# Skills

Reusable patterns and techniques that can be applied to other projects.

## Available Skills

| Skill | Description |
|-------|-------------|
| [goss](./goss/) | Test Docker containers with goss (volume or embedded patterns) |

### goss Patterns

| Pattern | Use Case | HEALTHCHECK |
|---------|----------|-------------|
| Volume | CLI tools, scratch images | No |
| Embedded | Services, long-running containers | Yes |

## Skill Structure

Each skill follows this structure:

```
skills/<skill-name>/
├── SKILL.yaml      # Metadata (name, version, requirements, usage)
├── README.md       # Full documentation
└── templates/      # Reusable code templates
```

## Using a Skill

1. Read the skill's `README.md` for full documentation
2. Copy templates from `templates/` to your project
3. Customize as needed
4. Follow the usage instructions in `SKILL.yaml`
