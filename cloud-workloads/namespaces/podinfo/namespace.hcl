# Level 1 -- the application.
#
# Facts that are true of podinfo wherever it runs. A second application would be
# a sibling directory reusing the same tf-modules and tg-modules unchanged.

locals {
  namespace = "podinfo"

  # Ownership and cost attribution. These become tags on every resource, so a
  # bill can be read by team rather than by resource type.
  owner       = "platform-engineering"
  cost_center = "platform"

  # How the workload identifies itself inside the cluster. Kept here because the
  # Helm chart in kubernetes-application/charts/podinfo-app uses the same values, and two
  # places disagreeing about a ServiceAccount name is a silent failure.
  kubernetes_namespace = "podinfo"
  service_account_name = "podinfo"
  helm_chart_name      = "podinfo-app"
  container_port       = 9898

  # Registry path the CI pipeline pushes to. See documentation/03-cicd.md.
  ecr_repository_name = "podinfo"

  # Prefix every Secrets Manager entry for this application shares, so IAM
  # grants can be scoped by path instead of enumerated secret by secret.
  secret_path_prefix = "podinfo"

  tags = {
    Application = "podinfo"
    Owner       = "platform-engineering"
    CostCenter  = "platform"
    ManagedBy   = "terragrunt"
    Repository  = "cloud-workloads"
  }
}
