# 🐘 PgAuditGraph

> Auditoria DML inteligente para PostgreSQL com visualização futura em Grafana

**PgAuditGraph** é uma solução leve e extensível de auditoria para bancos PostgreSQL, focada em registrar operações DML (INSERT, UPDATE, DELETE) com alta flexibilidade e controle por schema.  
Projetado para desenvolvedores, DBAs e equipes de infraestrutura que precisam de rastreabilidade confiável das alterações no banco de dados.

> Em breve: integração com Grafana para visualização em tempo real dos eventos auditados, com implantação simplificada via Docker.

---

## ✨ Funcionalidades

- 📌 Auditoria automática de **INSERT**, **UPDATE** e **DELETE**
- 🧠 Controle dinâmico por **schema** via tabela `audit.log_control`
- 🗂️ Logs estruturados em **JSONB**, com dados antigos e novos
- 🐘 100% compatível com **PostgreSQL puro** (sem extensões externas)
- ⚙️ Fácil de integrar com ferramentas como **Grafana**, **Prometheus** e **exporters**
- 🚀 Pronto para uso local ou em ambientes **Docker**

---

## 🏗️ Estrutura do Projeto

- `audit.validate_log`: Função principal que percorre os schemas ativados e cria/remova triggers de auditoria.
- `audit.log_control`: Tabela de controle que define os schemas a serem auditados.
- `audit.logging_dml`: Tabela de log onde os eventos são armazenados em formato JSONB.

---

## 📦 Instalação

1. Clone o repositório:

```bash
git clone https://github.com/seuusuario/PgAuditGraph.git
cd PgAuditGraph
