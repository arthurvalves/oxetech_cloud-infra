output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_ids" { value = [aws_subnet.public_1a.id, aws_subnet.public_1b.id] }
output "private_subnet_ids" { value = [aws_subnet.private_1a.id, aws_subnet.private_1b.id] }
output "public_1a_id" { value = aws_subnet.public_1a.id }
output "public_1b_id" { value = aws_subnet.public_1b.id }
output "private_1a_id" { value = aws_subnet.private_1a.id }
output "private_1b_id" { value = aws_subnet.private_1b.id }