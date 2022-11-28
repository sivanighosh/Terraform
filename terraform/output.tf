output "lb_dns_name" {
    description= "The DNSname of the load balancer"
    value = aws_lb.external-elb.DNSname
  }