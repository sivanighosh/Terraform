terraform{
    required_providers {
      aws = {
        source= "harsicorp/aws"
        version= "~>3.0"
      }
    }
}
#Configure AWS provider
provider "aws"{
    region= "us-east-1"

}