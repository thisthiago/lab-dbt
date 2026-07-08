import os
import random
from datetime import date, datetime, timedelta
from faker import Faker
from sqlalchemy import create_engine, insert
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

from models import Base, Empresa, Funcionario, Apontamento, Ferias, SolicitacaoAjuste

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), '.env'))

POSTGRES_USER = os.getenv('POSTGRES_USER', 'postgres')
POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD', 'postgres')
SISTEMAS_PORT = os.getenv('SISTEMAS_PORT', '5432')

# Create connections
URL_ADMIN = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@localhost:{SISTEMAS_PORT}/db_admin"
URL_MOTORISTAS = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@localhost:{SISTEMAS_PORT}/db_motoristas"

engine_admin = create_engine(URL_ADMIN)
engine_motoristas = create_engine(URL_MOTORISTAS)

SessionAdmin = sessionmaker(bind=engine_admin)
SessionMotoristas = sessionmaker(bind=engine_motoristas)

fake = Faker('pt_BR')

# Configuration
NUM_EMPRESAS = 3
NUM_FUNCIONARIOS_POR_EMPRESA = 200
DATA_INICIO_GERAL = date(2020, 1, 1)
DATA_FIM_GERAL = date(2026, 6, 30)
BATCH_SIZE = 50000

def reset_and_create_tables():
    print("Recreating tables...")
    Base.metadata.drop_all(engine_admin)
    Base.metadata.drop_all(engine_motoristas)
    Base.metadata.create_all(engine_admin)
    Base.metadata.create_all(engine_motoristas)

def generate_empresas():
    empresas = []
    for _ in range(NUM_EMPRESAS):
        empresas.append({
            'cnpj': fake.cnpj(),
            'razao_social': fake.company(),
            'endereco': fake.address().replace('\n', ', ')
        })
    return empresas

def generate_funcionarios(empresas_db, is_admin_db):
    funcionarios = []
    for emp in empresas_db:
        for _ in range(NUM_FUNCIONARIOS_POR_EMPRESA):
            # Admission date between 2018 and 2025
            data_admissao = fake.date_between_dates(date_start=date(2018, 1, 1), date_end=date(2025, 12, 31))
            
            # Dismissed logic (about 20% dismissed)
            is_dismissed = random.random() < 0.20
            data_demissao = None
            status = 'Ativo'
            if is_dismissed:
                # Dismissal must be after admission and before FIM_GERAL
                min_demissao = max(data_admissao, DATA_INICIO_GERAL)
                max_demissao = DATA_FIM_GERAL
                if min_demissao < max_demissao:
                    data_demissao = fake.date_between_dates(date_start=min_demissao, date_end=max_demissao)
                    status = 'Demitido'
            
            # Categorias
            categorias = ['Mensalista', 'Horista']
            if is_admin_db:
                categorias.append('Estagiário')
                # For admin, they can be in various departments
                setor = random.choice(['Financeiro', 'RH', 'TI', 'Administrativo', 'Marketing'])
                departamento = random.choice(['Operações', 'Estratégico'])
                cargo = random.choice(['Analista', 'Assistente', 'Gerente', 'Coordenador', 'Estagiário'])
            else:
                setor = 'Transporte'
                departamento = 'Logística'
                cargo = 'Motorista'
                
            categoria = random.choices(categorias, weights=[0.6, 0.3, 0.1] if is_admin_db else [0.6, 0.4])[0]
            if categoria == 'Estagiário':
                cargo = 'Estagiário'

            funcionarios.append({
                'empresa_id': emp.id,
                'nome': fake.name(),
                'cpf': fake.cpf(),
                'data_nascimento': fake.date_of_birth(minimum_age=18, maximum_age=65),
                'data_admissao': data_admissao,
                'data_demissao': data_demissao,
                'setor': setor,
                'departamento': departamento,
                'cargo': cargo,
                'categoria': categoria,
                'salario': round(random.uniform(1500, 15000), 2),
                'status': status
            })
    return funcionarios

def generate_ferias_for_func(func_id, admissao, demissao):
    ferias = []
    current_date = admissao
    end_date = demissao if demissao else DATA_FIM_GERAL
    
    # 1 year after admission they can take vacation
    current_date = current_date + timedelta(days=365)
    
    while current_date < end_date:
        # random start day within a 6 month window after acquiring right
        start_vacation = current_date + timedelta(days=random.randint(10, 180))
        end_vacation = start_vacation + timedelta(days=30)
        
        if start_vacation >= end_date:
            break
            
        if end_vacation > end_date:
            end_vacation = end_date
            
        ferias.append({
            'funcionario_id': func_id,
            'data_inicio': start_vacation,
            'data_fim': end_vacation
        })
        current_date = end_vacation + timedelta(days=365)
        
    return ferias

def is_on_vacation(check_date, ferias_list):
    for f in ferias_list:
        if f['data_inicio'] <= check_date <= f['data_fim']:
            return True
    return False

def get_punches(func_date, categoria):
    if categoria == 'Estagiário':
        return [
            datetime.combine(func_date, fake.time_object(end_datetime=datetime(2000,1,1,8,30))),
            datetime.combine(func_date, fake.time_object(end_datetime=datetime(2000,1,1,14,30)))
        ]
    else:
        return [
            datetime.combine(func_date, fake.time_object(end_datetime=datetime(2000,1,1,8,30))),
            datetime.combine(func_date, fake.time_object(end_datetime=datetime(2000,1,1,12,30))),
            datetime.combine(func_date, fake.time_object(end_datetime=datetime(2000,1,1,13,30))),
            datetime.combine(func_date, fake.time_object(end_datetime=datetime(2000,1,1,18,30)))
        ]

def populate_database(session, engine, is_admin_db, empresas_data):
    print(f"Populating {'Admin' if is_admin_db else 'Motoristas'} DB...")
    
    # Insert Empresas
    db_empresas = []
    for ed in empresas_data:
        e = Empresa(**ed)
        session.add(e)
        db_empresas.append(e)
    session.commit()
    
    # Insert Funcionarios
    funcionarios_data = generate_funcionarios(db_empresas, is_admin_db)
    session.execute(insert(Funcionario), funcionarios_data)
    session.commit()
    
    # Fetch them back to get IDs
    funcionarios_db = session.query(Funcionario).all()
    
    apontamentos = []
    solicitacoes = []
    ferias_all = []
    
    total_days = (DATA_FIM_GERAL - DATA_INICIO_GERAL).days + 1
    
    print(f"Generating data for {len(funcionarios_db)} employees over {total_days} days...")
    
    for idx, func in enumerate(funcionarios_db):
        if idx % 50 == 0:
            print(f"Processing employee {idx}/{len(funcionarios_db)}")
            
        func_ferias = generate_ferias_for_func(func.id, func.data_admissao, func.data_demissao)
        ferias_all.extend(func_ferias)
        
        start_date = max(func.data_admissao, DATA_INICIO_GERAL)
        end_date = min(func.data_demissao, DATA_FIM_GERAL) if func.data_demissao else DATA_FIM_GERAL
        
        current_date = start_date
        while current_date <= end_date:
            # Skip weekends
            if current_date.weekday() < 5 and not is_on_vacation(current_date, func_ferias):
                punches = get_punches(current_date, func.categoria)
                for i, p in enumerate(punches):
                    tipo = 'Entrada' if i % 2 == 0 else 'Saída'
                    apontamentos.append({
                        'funcionario_id': func.id,
                        'data_hora': p,
                        'tipo': tipo
                    })
                    
                # Solicitacao de ajuste (1% chance per day)
                if random.random() < 0.01:
                    solicitacoes.append({
                        'funcionario_id': func.id,
                        'data_solicitacao': current_date,
                        'data_hora_ajuste': punches[0], # Just an example
                        'motivo': random.choice(['Esquecimento', 'Problema no sistema', 'Trabalho externo']),
                        'status': random.choice(['Pendente', 'Aprovado', 'Reprovado'])
                    })
            
            current_date += timedelta(days=1)
            
            # Batch inserts to save memory
            if len(apontamentos) >= BATCH_SIZE:
                session.execute(insert(Apontamento), apontamentos)
                session.commit()
                apontamentos = []
            if len(solicitacoes) >= BATCH_SIZE:
                session.execute(insert(SolicitacaoAjuste), solicitacoes)
                session.commit()
                solicitacoes = []
                
    # Insert remaining
    if apontamentos:
        session.execute(insert(Apontamento), apontamentos)
    if solicitacoes:
        session.execute(insert(SolicitacaoAjuste), solicitacoes)
    if ferias_all:
        session.execute(insert(Ferias), ferias_all)
        
    session.commit()
    print("Population complete.")

if __name__ == '__main__':
    reset_and_create_tables()
    
    empresas_data = generate_empresas()
    
    with SessionAdmin() as s_admin:
        populate_database(s_admin, engine_admin, is_admin_db=True, empresas_data=empresas_data)
        
    with SessionMotoristas() as s_mot:
        populate_database(s_mot, engine_motoristas, is_admin_db=False, empresas_data=empresas_data)
