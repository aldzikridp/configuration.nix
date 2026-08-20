# Nix derivation for `pg-semantic-search` (CLI: `semsearch`).
#
# A semantic search service over local documents using LangChain + PostgreSQL + pgvector.
# Ingest files (PDF, CSV, JSON, TXT, MD), split into chunks, generate embeddings,
# and search by meaning — not just keywords.
#
# Build via:
#   pkgs.python3Packages.callPackage ../pkgs/semsearch/default.nix { }
#
# Usage (after adding to home.packages and configuring .env):
#   semsearch init                  # Create database table
#   semsearch ingest docs/file.md   # Ingest a file
#   semsearch search "query"        # Search
#   semsearch --help                # Show all commands
#
# Configuration: all via environment variables or .env file.
# See https://github.com/aldzikridp/semantic-search for full docs.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  pythonRelaxDepsHook,
  callPackage,
  # Runtime deps — mirror [project.dependencies] in pyproject.toml
  langchain,
  langchain-core,
  langchain-community,
  langchain-text-splitters,
  psycopg,
  pgvector,
  sqlalchemy,
  pydantic,
  pydantic-settings,
  typer,
  pymupdf,
  python-dotenv,
  jq,
  # Provider extras — [project.optional-dependencies.all]
  langchain-openai,
  langchain-ollama,
}:

let
  # langchain-postgres is not in nixpkgs — build it from our local derivation.
  langchain-postgres = callPackage ./langchain-postgres.nix { };
in
buildPythonPackage rec {
  pname = "pg-semantic-search";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "aldzikridp";
    repo = "semantic-search";
    rev = "81a378340e94df884c8d80015f4d7c96e3453e81";
    hash = "sha256-TsEeMuvcEWDdj4ZBCR4LB5qXCJ0hlGAGN640AfbeUUs=";
  };

  pyproject = true;
  build-system = [ hatchling ];

  # Relax version constraints — nixpkgs may ship newer versions than
  # the >= lower bounds in pyproject.toml.
  pythonRelaxDeps = true;
  nativeBuildInputs = [ pythonRelaxDepsHook ];

  propagatedBuildInputs = [
    # Core runtime deps
    langchain
    langchain-core
    langchain-postgres
    langchain-community
    langchain-text-splitters
    psycopg
    pgvector
    sqlalchemy
    pydantic
    pydantic-settings
    typer
    pymupdf
    python-dotenv
    jq
    # Provider extras (openai + ollama)
    langchain-openai
    langchain-ollama
  ];

  # Tests require a running PostgreSQL + pgvector instance (testcontainers).
  # Not suitable for the Nix build sandbox.
  doCheck = false;

  pythonImportsCheck = [ "semsearch" ];

  meta = with lib; {
    description = "Semantic search over local documents using LangChain + PostgreSQL + pgvector";
    homepage = "https://github.com/aldzikridp/semantic-search";
    license = licenses.mit;
    mainProgram = "semsearch";
    platforms = platforms.linux;
  };
}
