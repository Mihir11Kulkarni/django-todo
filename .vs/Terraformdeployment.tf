provider "aws" {
  region = "us-west-1"  # Update with your desired region
}

# Create Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "newbeanstalkforazuredeployment" {
  name        = "newbeanstalkforazuredeployment"  # Update with your desired application name
  description = "My .NET Core Application"  # Update with your application description
}

# Create Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "newbeanstalkforazuredeployment" {
  name                = "newbeanstalkforazuredeployment"  # Update with your desired environment name
  application         = aws_elastic_beanstalk_application.newbeanstalkforazuredeployment
  solution_stack_name = "Windows IIS 10.0 running on 64-bit Windows Server 2019"  # Update with the appropriate solution stack name

  # Configuration settings
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:dotnetcore"
    name      = "DotnetCoreVersion"
    value     = "3.1"  # Update with your desired .NET Core version
  }
}

# Create IAM role for the release pipeline
resource "aws_iam_role" "release_role" {
  name = "MyReleaseRole"  # Update with your desired role name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach necessary policies to the release role
resource "aws_iam_role_policy_attachment" "release_role_attachment" {
  role       = aws_iam_role.release_role.name
  policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AWSElasticBeanstalkServiceRolePolicy"  # Attach appropriate policy ARNs based on your requirements
}

# Create AWS CodePipeline for deployment
resource "aws_codepipeline" "my_pipeline" {
  name     = "MyPipeline"  # Update with your desired pipeline name
  role_arn = arn:aws:iam::211180857997:policy/elasticbeanstalkFORAzureRelesePipline

  artifact_store {
    location = "news3forazuredeployment"  # Update with your S3 bucket name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "newbeanstalkforazuredeployment"
      category         = "Source"
      owner            = "mihirKulkarni"
      provider         = "AzureRepos"
      version          = "1"
      output_artifacts = ["https://dev.azure.com/mihirkulkarni11/_apis/resources/Containers/5358158/drop?itemPath=drop%2FWeb.zip", "https://dev.azure.com/mihirkulkarni11/_apis/resources/Containers/5358158/drop?itemPath=drop%2FBlazorAdmin.zip"]

      configuration = {
        Owner      = "mihirkulkarni11/"
        Repo       = "eShopOnWeb"
        Branch     = "main"
        OAuthToken = "gah27lvhkbvnytl55hzh7okawbydty7x7gvzwb3l2kn2gvmq6lna"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "DeployAction"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ElasticBeanstalk"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["https://dev.azure.com/mihirkulkarni11/_apis/resources/Containers/5358158/drop?itemPath=drop%2FWeb.zip", "https://dev.azure.com/mihirkulkarni11/_apis/resources/Containers/5358158/drop?itemPath=drop%2FBlazorAdmin.zip" ]

      configuration = {
        ApplicationName         = newbeanstalkforazuredeployment
        EnvironmentName         = aws_elastic_beanstalk_environment.newbeanstalkforazuredeployment
        VersionLabel            = "MyApplicationVersionV1"  # Update with your desired version label
        WaitForReadyTimeoutMins = "10"  # Update with your desired timeout
      }
    }
  }
}
