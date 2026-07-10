import pandas as pd
from sqlalchemy import create_engine, text

# =============================================================================
# Script de EL (Extract, Load) — Substitui o FDW
#
# Em projetos reais, ferramentas como Airbyte ou scripts Python puxam os 
# dados do sistema transacional (OLTP) e gravam numa camada RAW do Data Warehouse.
# O dbt entrará em ação *depois* disso, transformando (T) esses dados brutos.
# =============================================================================

# URIs de conexão mapeadas pelo docker-compose
URL_ADMIN = "postgresql://postgres:postgres@localhost:5454/db_admin"
URL_MOTORISTAS = "postgresql://postgres:postgres@localhost:5454/db_motoristas"
URL_DW = "postgresql://postgres:postgres@localhost:5455/db_dw"

def load_data():
    print("Conectando aos bancos de dados...")
    engine_admin = create_engine(URL_ADMIN)
    engine_motoristas = create_engine(URL_MOTORISTAS)
    engine_dw = create_engine(URL_DW)

    # Recria os schemas limpos no DW
    with engine_dw.connect() as conn:
        conn.execute(text("DROP SCHEMA IF EXISTS raw_admin CASCADE;"))
        conn.execute(text("DROP SCHEMA IF EXISTS raw_motoristas CASCADE;"))
        conn.execute(text("CREATE SCHEMA raw_admin;"))
        conn.execute(text("CREATE SCHEMA raw_motoristas;"))
        conn.commit()

    # ==========================================
    # EXTRACT (Extração do db_admin)
    # ==========================================
    print("Extraindo dados de funcionários do sistema administrativo...")
    df_funcionarios_admin = pd.read_sql("SELECT * FROM funcionario", engine_admin)
    print(f"   - {len(df_funcionarios_admin)} funcionários lidos.")

    print("Extraindo apontamentos do sistema administrativo...")
    df_apontamentos_admin = pd.read_sql("SELECT * FROM apontamento", engine_admin)
    print(f"   - {len(df_apontamentos_admin)} apontamentos lidos.")

    # ==========================================
    # EXTRACT (Extração do db_motoristas)
    # ==========================================
    print("Extraindo dados de motoristas...")
    df_funcionarios_mot = pd.read_sql("SELECT * FROM funcionario", engine_motoristas)
    print(f"   - {len(df_funcionarios_mot)} motoristas lidos.")

    print("Extraindo apontamentos dos motoristas...")
    df_apontamentos_mot = pd.read_sql("SELECT * FROM apontamento", engine_motoristas)
    print(f"   - {len(df_apontamentos_mot)} apontamentos lidos.")

    # ==========================================
    # LOAD (Carga no db_dw)
    # ==========================================
    print("Carregando dados no Data Warehouse...")
    
    # Gravando admin
    df_funcionarios_admin.to_sql(
        "funcionario", 
        engine_dw, 
        schema="raw_admin", 
        if_exists="replace", 
        index=False
    )
    df_apontamentos_admin.to_sql(
        "apontamento", 
        engine_dw, 
        schema="raw_admin", 
        if_exists="replace", 
        index=False
    )

    # Gravando motoristas
    df_funcionarios_mot.to_sql(
        "funcionario", 
        engine_dw, 
        schema="raw_motoristas", 
        if_exists="replace", 
        index=False
    )
    df_apontamentos_mot.to_sql(
        "apontamento", 
        engine_dw, 
        schema="raw_motoristas", 
        if_exists="replace", 
        index=False
    )

    print("Carga completa! O Data Warehouse está populado e pronto para o dbt rodar as transformações.")

if __name__ == "__main__":
    load_data()
