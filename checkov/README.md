# Checkov Docker Image

Docker packaging for [Checkov](https://www.checkov.io/), a static analysis tool for infrastructure-as-code security scanning.

## Usage

```bash
# Scan Terraform files in current directory
docker run --rm -v $(pwd):/src timjdfletcher/checkov -d /src

# Scan a specific file
docker run --rm -v $(pwd):/src timjdfletcher/checkov -f /src/main.tf

# Scan with specific checks
docker run --rm -v $(pwd):/src timjdfletcher/checkov -d /src --check CKV_AWS_1,CKV_AWS_2

# Output as JSON
docker run --rm -v $(pwd):/src timjdfletcher/checkov -d /src -o json
```

## Supported Frameworks

Checkov supports scanning:
- Terraform (HCL, JSON, plan files)
- CloudFormation
- Kubernetes
- Helm
- Dockerfiles
- ARM templates
- Serverless framework
- And more

## Build

```bash
./run build
```

## Release

```bash
git tag checkov-v<version>
./run release
```
