provider "aws" {
    region = "eu-west-2"
}

resource "aws_instance" "myfirstinstance" {
    ami           = "ami-05f37c3995fffb4fd"
    instance_type = "t2.micro"

    tags = {
        Name = "irfan-first-instance"
    }
}