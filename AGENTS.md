# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AshTypescript is a library for generating TypeScript types from Ash resources and actions. It provides automatic TypeScript type generation for Ash APIs, ensuring type safety between Elixir backend and TypeScript frontend.

## Common Development Commands

### Build & Testing
```bash
# Compile the project
mix compile

# Run tests
mix test

# Run specific test file
mix test test/ts_codegen_test.exs

# Generate TypeScript types (test command)
mix test.codegen

# Run TypeScript compilation tests
cd test/ts && npm run compile
```

### Code Quality
```bash
# Run credo for code analysis (strict mode)
mix credo

# Run security checks
mix sobelow

# Format code with Spark formatter
mix spark.formatter

# Generate documentation
mix docs
```

### TypeScript Code Generation
```bash
# Generate TypeScript types from all JSON files in default directory
mix ash_typescript.codegen

# Generate with custom output file
mix ash_typescript.codegen --output "assets/js/generated_types.ts"

# Generate with custom RPC endpoints
mix ash_typescript.codegen --run_endpoint "/api/rpc/run" --validate_endpoint "/api/rpc/validate"

# Check mode (verifies if generated code matches expected)
mix ash_typescript.codegen --check

# Dry run mode (shows what would be generated)
mix ash_typescript.codegen --dry_run
```

## Architecture & Key Components

### Core Structure
- **`lib/ash_typescript/codegen.ex`** - Main TypeScript code generation logic. Transforms Ash resources into TypeScript interfaces, Zod schemas, and RPC call functions.
- **`lib/ash_typescript/rpc.ex`** - DSL for defining RPC specifications within Ash resources.
- **`lib/ash_typescript/filter.ex`** - Handles filter-related TypeScript generation.
- **`lib/mix/tasks/ash_typescript.codegen.ex`** - Mix task that orchestrates the code generation process.

### Key Concepts
1. **RPC Specifications**: JSON files in `assets/js/ash_rpc/` define which Ash actions to generate TypeScript for and which fields to select.
2. **Type Generation**: Creates TypeScript interfaces, Zod validation schemas, and type-safe RPC call functions.
3. **Field Selection**: Supports selecting specific fields and loading relationships with constraints.

### Testing Setup
- Tests use a test domain with example resources (Todo, User, Comment)
- TypeScript compilation tests verify generated code compiles correctly
- Test TypeScript setup in `test/ts/` with its own package.json

## Important Development Notes

- This is an Ash Framework extension - always use Ash patterns and concepts
- The generated TypeScript includes both runtime validation (Zod) and compile-time types
- RPC endpoints are configurable via mix task options or application config
- The library supports all Ash action types: read, create, update, destroy, and custom actions