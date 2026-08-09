# Take-Home Assignment — DevOps Engineer (AWS Focused)

## Overview

The goal of this assignment is to deploy a small web app into a **local Kubernetes cluster** (kind or minikube), package it with Helm, and describe how you'd migrate and operate it in an **AWS** environment. 

Everything runs locally and for free — **no active AWS cloud account is required for the practical part**.

> 💡 **A note on scope and depth:**
> We highly value your personal time, so we design our tasks to be lightweight. We do **not** expect 100% of the items to be completed to absolute perfection. We are much more interested in seeing **how you prioritize tasks**, **what conscious trade-offs you make**, and your general architectural approach. A clean, working setup that covers the core items always beats an over-engineered solution that doesn't spin up.

> 🛑 **The "Good Enough" Rule:** If you find yourself spending too much time troubleshooting a specific local tool configuration, feel free to stop, drop a quick note about the issue in your README, and move on to the next section.

---

## Technical Tasks

You can use **any ready-made app** — your own project, a public demo, or a basic hello-world in any language. **You do not need to write application code.** It just needs to provide an HTTP endpoint.

### Core Implementation (Recommended Focus)

1. **Cluster Setup.** Spin up a local cluster with `kind` or `minikube`. The command or manifest to create it should live in your repository.
   * *Tip:* If using `kind`, you can use `kind load docker-image` to move your local app image into the cluster without pushing it to a remote registry.
2. **Deployment.** Run the app in the cluster. At minimum, provide a Deployment and a Service. Accessing the app from outside via `port-forward` is perfectly acceptable.
3. **Helm Packaging.** Package the deployment manifests into a Helm chart. Key parameters (such as image tags, replica count, and resource allocations) should be driven through `values.yaml`. Feel free to build the chart from scratch if it's easier for you than cleaning up a default `helm create` template.
4. **Configuration & Secrets.** Show how you separate environment configuration from sensitive data (using ConfigMaps, Secrets, or your preferred local approach). Briefly explain your choice in the README.
5. **Documentation.** Provide clear, straightforward instructions in your README to bring the entire local environment up from scratch.

### Optional Extensions (Pick 1–2 items based on interest)

*Choose what aligns best with your strengths or what you'd like to showcase:*

* **Resilience.** Add liveness/readiness probes, requests/limits, and either an HPA or a PodDisruptionBudget. Briefly mention why you chose those specific settings.
* **CI/CD Automation (AWS Target).** Write a pipeline configuration (GitHub Actions, GitLab CI, etc.) outlining the workflow: build -> lint/test -> push image to **AWS ECR** -> deploy to **AWS EKS**. *You do not need to run this pipeline — just write the YAML and briefly explain the AWS authentication approach (e.g., OIDC).*
* **Database Integration.** Run a PostgreSQL instance in the local cluster (via StatefulSet or a community Helm chart) and wire the app to it. In your documentation, describe how you would map this component to an AWS managed service (like Amazon RDS/Aurora).
* **Ingress & TLS.** Set up a local Ingress controller. In the documentation, explain how this setup would translate to AWS using the **AWS Load Balancer Controller** (ALB) and **AWS Certificate Manager (ACM)**.

---

## Architectural Discussion (Put in README or `NOTES.md`)

*We love reading your thoughts on production design. Please include short answers to the following questions:*

1. **Trade-offs:** What parts of the implementation did you decide to skip or simplify, and why?
2. **Local vs AWS Production:** Name 3–5 concrete things that are currently "test-only" in your local setup but would be handled differently in a true AWS production environment (e.g., Networking/VPC, IAM, state management).
3. **AWS Security & Secrets:** How would you securely pass secrets to pods in AWS EKS? (e.g., AWS Secrets Manager + External Secrets Operator vs CSI Driver, IAM Roles for Service Accounts). What is your preferred approach?
4. **Infrastructure as Code (IaC):** If you had to provision the AWS infrastructure (VPC, EKS cluster, RDS) for this app tomorrow, what tool would you choose (Terraform, OpenTofu, AWS CDK, etc.) and how would you structure the project?

---

## Evaluation Criteria

* **Clarity over Complexity:** Sound engineering decisions and the ability to explain *"why,"* not just *"what."*
* **AWS Awareness:** A solid understanding of AWS best practices (Security, IAM, Managed Services) applied conceptually to the local setup.
* **Pragmatism:** Honest documentation regarding trade-offs, limitations, and what was left out of scope.

## Submission

* Send us a link to your Git repository (public or private access).
* Don't worry about squashing or making a perfect commit history — work in whatever style feels natural to you.
* If something doesn't run perfectly on the local machine, don't sweat it — just document the roadblock in the README. We'll talk through it together during the interview!