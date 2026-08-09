# Container registry for the application image.
#
# The GitLab pipeline mirrors the upstream podinfo image in here under the
# commit SHA (documentation/03-cicd.md). Deploys then stop depending on a third
# party's registry being up, and the image that was scanned is the image that
# ships.

locals {
  repository_name = "${var.namespace}/${var.ecr_repository_name}"

  tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  })
}

resource "aws_ecr_repository" "this" {
  name = local.repository_name

  # A tag that can be moved makes `helm rollback` meaningless -- the old tag may
  # point at different bytes by the time you roll back. This is the registry-side
  # enforcement of the same rule the chart follows by never using :latest.
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn == null ? "AES256" : "KMS"
    kms_key         = var.kms_key_arn
  }

  # Refuses to delete a repository that still holds images.
  force_delete = !var.deletion_protection

  tags = local.tags
}

# Untagged layers accumulate from every overwritten manifest and are billed like
# any other storage. Tagged images are kept by count, not by age -- an image
# still running in production must not expire because it is old.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the most recent tagged images"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["sha-"]
          countType   = "imageCountMoreThan"
          countNumber = var.tagged_image_retention_count
        }
        action = { type = "expire" }
      },
    ]
  })
}

# Lets other accounts in the organisation pull without a second copy of the
# image. Pull only -- pushing stays with the pipeline that built it.
resource "aws_ecr_repository_policy" "cross_account_pull" {
  count = length(var.pull_account_ids) > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "CrossAccountPull"
      Effect = "Allow"
      Principal = {
        AWS = [for id in var.pull_account_ids : "arn:aws:iam::${id}:root"]
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
      ]
    }]
  })
}
