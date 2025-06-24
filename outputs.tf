output "rds_endpoint" {
  description = "RDS Endpoint for MySQL"
  value       = aws_db_instance.mysql.endpoint
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = aws_eks_cluster.eks.endpoint
}
