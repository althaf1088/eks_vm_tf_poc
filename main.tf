variable "eks_cluster_name" {}
variable "region" {}
variable "instance_type" {
  default = "t2.small"
}
variable "workers_additional_policies" {
  default = []
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name                 = "ekstf-vpc"
  cidr                 = "192.168.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["192.168.160.0/19", "192.168.128.0/19", "192.168.96.0/19"]
  public_subnets       = ["192.168.64.0/19", "192.168.32.0/19", "192.168.0.0/19"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared",
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "12.2.0"
  cluster_name = var.eks_cluster_name
  cluster_version = "1.17"
  subnets      = module.vpc.private_subnets
  vpc_id       = module.vpc.vpc_id

  workers_additional_policies = var.workers_additional_policies

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = var.instance_type
      asg_desired_capacity = 2
    }
  ]
}

provider "kubernetes" {
   config_path = "kubeconfig_eks_poc"
}
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}
provider "helm" {
  kubernetes {
    config_path = "kubeconfig_${var.eks_cluster_name}"
  }
}
resource "helm_release" "victoriametrics" {
  name       = "vm"
  repository = "https://victoriametrics.github.io/helm-charts/" 
  chart      = "victoria-metrics-cluster"
  namespace = "prometheus"
}

data "helm_repository" "stable" {
    name = "stable"
    url = "https://kubernetes-charts.storage.googleapis.com"
}

resource "helm_release" "prometheus" {
  
    provider = "helm"
    name = "prometheus"
    repository = "${data.helm_repository.stable.metadata.0.name}"
    chart = "prometheus"
    namespace = "prometheus" 
    values = [
      "${file("values.yaml")}"
    ]

}
