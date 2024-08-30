region = "us-east-1"

ami_filters = {
  type = {
    name   = "virtualization-type"
    values = "hvm"
  }
  name = {
    name   = "name"
    values = "packer-jenkins-amazon-linux-Apificacion-*"
  }
}

instance_type = "t3.large"

monitoring = true


associate_public_ip_address = false

root_volume = {
  size = "100"
  type = "gp2"
}

roles = {
  jenkins-slave = {
    CloudWatchAndLogsPolicy = {
      description = "Política para CloudWatch y Logs"
      file        = "cloudwatch_and_logs_policy.json"
    }
    SSMPolicy = {
      description = "Política de SSM"
      file        = "ssm_policy.json"
    }
    EKSPolicy = {
      description = "Política de EKS"
      file        = "eks_policy.json"
    }
    SSMPolicyEast1 = {
      description = "Política de SSM Bancoppel east-1"
      file        = "ssm_policy_east-1.json"
    }
  }
}

partial_name = "apificacion-jenkins-slave"

private_ip = "10.209.10.5"

environment = "dev"

tags = {
  "Application Role" = "web server",
  "Project"          = "Unity",
  "Owner"            = "Brenda Pichardo",
  "Cost Center"      = "Pendiente",
  "Business Unit"    = "Apificacion"
}
