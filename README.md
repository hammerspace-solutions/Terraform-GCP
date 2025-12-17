# Hammerspace on Google Cloud Platform - Terraform Deployment

This Terraform project automates the deployment of Hammerspace Global Data Environment on Google Cloud Platform (GCP), providing a production-ready infrastructure setup for high-performance data management.

## Architecture Overview

The deployment creates a complete Hammerspace cluster with:
- **Anvil Metadata Servers (MDS)**: Manage metadata and orchestrate data operations
- **DSX Data Servers**: Provide scale-out storage capacity
- **ECGroup Nodes**: Support erasure coding for data protection
- **Storage Servers**: Additional storage nodes with RAID configurations
- **Client Instances**: Test and access the Hammerspace file system
- **Ansible Controller**: Automates configuration management

## Prerequisites

### Required Tools
- Terraform >= 1.5.0
- Google Cloud SDK (`gcloud`)
- SSH client
- Git

### GCP Requirements
- Active GCP project with billing enabled
- Compute Engine API enabled
- Required IAM permissions:
  - `compute.admin`
  - `iam.serviceAccountAdmin`
  - `resourcemanager.projectIamAdmin`

### Hammerspace Requirements
- Valid Hammerspace license
- Access to Hammerspace software packages
- Network connectivity for cluster communication

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd Terraform-GCP
```

### 2. Authenticate with GCP
```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 3. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration:
```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"

# Network Configuration
vpc_network_name = "hammerspace-vpc"
subnet_name      = "hammerspace-subnet"
subnet_cidr      = "10.0.0.0/24"

# Hammerspace Configuration
goog_cm_deployment_name = "hammerspace-prod"
admin_user            = "admin"
admin_user_password   = "secure-password-here"

# Instance Configuration
anvil_machine_type = "n2-standard-8"
dsx_machine_type   = "n2-standard-16"
```

### 4. Initialize Terraform
```bash
terraform init
```

### 5. Review the Plan
```bash
terraform plan
```

### 6. Deploy
```bash
terraform apply
```

## Configuration Details

### Network Architecture
- Creates a dedicated VPC network with custom subnets
- Configures firewall rules for Hammerspace communication
- Supports both internal and external access patterns

### Instance Types and Sizing

#### Anvil Metadata Servers
- Default: `n2-standard-8` (8 vCPUs, 32 GB memory)
- Minimum: 4 vCPUs, 16 GB memory
- Recommended for production: 8+ vCPUs, 32+ GB memory

#### DSX Data Servers
- Default: `n2-standard-16` (16 vCPUs, 64 GB memory)
- Storage: Multiple persistent disks or local SSDs
- Network: High-bandwidth configuration

#### Storage Configuration
- Boot disks: 100 GB SSD persistent disks
- Data disks: Configurable size and type
- Optional KMS encryption for all disks

### High Availability
- Placement policies for node distribution
- Multi-zone deployment support
- Automatic failover capabilities

## Module Structure

```
.
├── modules/
│   ├── iam-core/         # Service accounts and IAM
│   ├── ansible/           # Ansible controller setup
│   ├── clients/           # Client instances
│   ├── storage_servers/   # Storage server nodes
│   ├── hammerspace/       # Anvil and DSX instances
│   └── ecgroup/           # ECGroup nodes
├── 10-global.tf           # Global variables
├── 20-ansible.tf          # Ansible variables
├── 40-clients.tf          # Client variables
├── 50-ecgroup.tf          # ECGroup variables
├── 60-hammerspace.tf      # Hammerspace variables
├── 70-storage-servers.tf  # Storage server variables
├── main.tf                # Root module
└── outputs.tf             # Output definitions
```

## Security Best Practices

### Network Security
- Implements least-privilege firewall rules
- Uses private IP addresses for internal communication
- Optional public IPs only where required

### Identity and Access Management
- Creates dedicated service accounts
- Applies minimal required permissions
- Supports customer-managed encryption keys (CMEK)

### Data Protection
- KMS encryption for all disks
- Secure boot enabled by default
- SSH key management via Ansible

## Operations

### Accessing Instances
```bash
# SSH to Ansible controller
gcloud compute ssh ansible-controller --zone=us-central1-a

# SSH to Anvil node
gcloud compute ssh hammerspace-mds-1 --zone=us-central1-a
```

### Monitoring
- Use Google Cloud Console for instance monitoring
- Check Hammerspace web UI on Anvil nodes
- Review logs in Cloud Logging

### Scaling

#### Adding Nodes
1. Update `terraform.tfvars`:
```hcl
anvil_node_count = 3  # Increase from current
dsx_node_count = 6    # Increase from current
```
2. Run `terraform apply`

#### Removing Nodes
1. Set removal variables:
```hcl
anvil_nodes_to_remove = ["hammerspace-mds-3"]
dsx_nodes_to_remove = ["hammerspace-dsx-6"]
```
2. Run `terraform apply`
3. Clear removal variables after completion

### Backup and Recovery
- State file stored in GCS bucket (if backend configured)
- Regular snapshots of persistent disks
- Hammerspace native data protection features

## Troubleshooting

### Common Issues

#### Authentication Errors
```bash
# Re-authenticate with GCP
gcloud auth application-default login
```

#### API Not Enabled
```bash
# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
```

#### Quota Exceeded
- Check quotas in GCP Console
- Request quota increases if needed
- Consider different regions/zones

### Getting Help
- Review Terraform logs: `terraform apply -debug`
- Check instance serial console output
- Review Hammerspace logs on Anvil nodes

## Advanced Configuration

### Custom Machine Types
```hcl
# In terraform.tfvars
anvil_machine_type = "custom-8-32768"  # 8 vCPUs, 32 GB RAM
```

### Placement Policies
```hcl
# Spread instances across zones
anvil_placement_policy_name = "anvil-spread-policy"
dsx_placement_policy_name = "dsx-spread-policy"
```

### KMS Encryption
```hcl
# Use customer-managed keys
kms_key = "projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY"
```

## Cost Optimization

### Recommendations
- Use committed use discounts for production
- Consider preemptible instances for non-critical workloads
- Right-size instances based on actual usage
- Use regional persistent disks for better pricing

### Cost Estimation
Use the [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator) with:
- Compute Engine instances
- Persistent Disk storage
- Network egress estimates

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will delete all instances and data. Ensure backups are complete before destroying.

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For Hammerspace-specific issues:
- Contact Hammerspace Support
- Review [Hammerspace Documentation](https://www.hammerspace.com/docs)

For Terraform/GCP issues:
- Check this README and inline documentation
- Review [Terraform GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- Open an issue in this repository

## Version History

- v1.0.0 - Initial GCP implementation
  - Full feature parity with AWS version
  - Support for Hammerspace deployment guide
  - KMS encryption support
  - Node add/remove procedures