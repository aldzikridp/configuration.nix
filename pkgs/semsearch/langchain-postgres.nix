# Nix derivation for `langchain-postgres` — NOT in nixpkgs as of 26.05.
#
# This is a dependency of `pg-semantic-search` (semsearch). It is packaged
# here rather than upstream because it's only used by semsearch in this config.
#
# Build via:
#   pkgs.python3Packages.callPackage ./langchain-postgres.nix { }
#
# Note: pgvector constraint `>=0.2.5,<0.4` is relaxed because nixpkgs ships
# 0.4.x. The library works fine with pgvector 0.4.x — the constraint was
# conservative upstream.
{
  lib,
  buildPythonPackage,
  fetchurl,
  hatchling,
  pythonRelaxDepsHook,
  # Runtime deps
  asyncpg,
  langchain-core,
  pgvector,
  psycopg,
  psycopg-pool,
  sqlalchemy,
  numpy,
}:

buildPythonPackage rec {
  pname = "langchain-postgres";
  version = "0.0.17";

  # fetchPypi fails for this package (name normalization issue),
  # so use fetchurl with the direct PyPI download URL.
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/58/16/27327ba9b12aa4835cfc1dad3ece7be13ec0f1619c42329640382251e87d/langchain_postgres-0.0.17.tar.gz";
    hash = "sha256-jQ1PgiPz10Rxq9ZA5BczFvmHTyj0F9Z0zIsLUO5zXAk=";
  };

  pyproject = true;
  build-system = [ hatchling ];

  # Relax pgvector upper bound (<0.4) — nixpkgs ships 0.4.x which is compatible.
  pythonRelaxDeps = [
    "pgvector"
  ];

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  propagatedBuildInputs = [
    asyncpg
    langchain-core
    pgvector
    psycopg
    psycopg-pool
    sqlalchemy
    numpy
  ];

  # Tests require a running PostgreSQL instance.
  doCheck = false;

  pythonImportsCheck = [ "langchain_postgres" ];

  meta = with lib; {
    description = "An integration package connecting Postgres and LangChain";
    homepage = "https://github.com/langchain-ai/langchain-postgres";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
