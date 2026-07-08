from sqlalchemy import Column, Integer, String, Date, DateTime, Numeric, ForeignKey
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

class Empresa(Base):
    __tablename__ = 'empresa'
    
    id = Column(Integer, primary_key=True)
    cnpj = Column(String(18), unique=True, nullable=False)
    razao_social = Column(String(150), nullable=False)
    endereco = Column(String(200))
    
    funcionarios = relationship("Funcionario", back_populates="empresa")

class Funcionario(Base):
    __tablename__ = 'funcionario'
    
    id = Column(Integer, primary_key=True)
    empresa_id = Column(Integer, ForeignKey('empresa.id'), nullable=False)
    nome = Column(String(150), nullable=False)
    cpf = Column(String(14), unique=True, nullable=False)
    data_nascimento = Column(Date, nullable=False)
    data_admissao = Column(Date, nullable=False)
    data_demissao = Column(Date, nullable=True)
    setor = Column(String(100), nullable=False)
    departamento = Column(String(100), nullable=False)
    cargo = Column(String(100), nullable=False)
    categoria = Column(String(50), nullable=False) # Horista, Mensalista, Estagiário
    salario = Column(Numeric(10, 2), nullable=False)
    status = Column(String(20), nullable=False) # Ativo, Demitido
    
    empresa = relationship("Empresa", back_populates="funcionarios")
    apontamentos = relationship("Apontamento", back_populates="funcionario")
    ferias = relationship("Ferias", back_populates="funcionario")
    solicitacoes_ajuste = relationship("SolicitacaoAjuste", back_populates="funcionario")

class Apontamento(Base):
    __tablename__ = 'apontamento'
    
    id = Column(Integer, primary_key=True)
    funcionario_id = Column(Integer, ForeignKey('funcionario.id'), nullable=False)
    data_hora = Column(DateTime, nullable=False)
    tipo = Column(String(10), nullable=False) # Entrada, Saída
    
    funcionario = relationship("Funcionario", back_populates="apontamentos")

class SolicitacaoAjuste(Base):
    __tablename__ = 'solicitacao_ajuste'
    
    id = Column(Integer, primary_key=True)
    funcionario_id = Column(Integer, ForeignKey('funcionario.id'), nullable=False)
    data_solicitacao = Column(Date, nullable=False)
    data_hora_ajuste = Column(DateTime, nullable=False)
    motivo = Column(String(255), nullable=False)
    status = Column(String(20), nullable=False) # Pendente, Aprovado, Reprovado
    
    funcionario = relationship("Funcionario", back_populates="solicitacoes_ajuste")

class Ferias(Base):
    __tablename__ = 'ferias'
    
    id = Column(Integer, primary_key=True)
    funcionario_id = Column(Integer, ForeignKey('funcionario.id'), nullable=False)
    data_inicio = Column(Date, nullable=False)
    data_fim = Column(Date, nullable=False)
    
    funcionario = relationship("Funcionario", back_populates="ferias")
