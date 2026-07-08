import os
from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import desc, func, extract, cast, Date, and_, or_
from typing import Optional
from pydantic import BaseModel
from datetime import date, datetime
from database import get_db_admin, get_db_motoristas
import models

app = FastAPI(title="Ponto Eletrônico API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Schemas ────────────────────────────────────────────────

class LoginData(BaseModel):
    username: str
    password: str

# ─── Dependency: resolve DB from system param ──────────────

def _resolve_db(system: str, db_admin: Session = Depends(get_db_admin), db_motoristas: Session = Depends(get_db_motoristas)):
    if system == "admin":
        return db_admin
    if system == "motoristas":
        return db_motoristas
    raise HTTPException(400, "Sistema inválido. Use 'admin' ou 'motoristas'.")

# ─── Auth ───────────────────────────────────────────────────

@app.post("/api/login")
def login(data: LoginData):
    if data.username == os.getenv("WEB_USER", "admin") and data.password == os.getenv("WEB_PASSWORD", "admin"):
        return {"token": "session-token", "user": data.username}
    raise HTTPException(401, "Credenciais inválidas")

# ─── Dashboard KPIs ────────────────────────────────────────

@app.get("/api/{system}/dashboard")
def dashboard(system: str, db: Session = Depends(_resolve_db)):
    total = db.query(func.count(models.Funcionario.id)).scalar()
    ativos = db.query(func.count(models.Funcionario.id)).filter(models.Funcionario.status == "Ativo").scalar()
    demitidos = db.query(func.count(models.Funcionario.id)).filter(models.Funcionario.status == "Demitido").scalar()
    estagiarios = db.query(func.count(models.Funcionario.id)).filter(models.Funcionario.categoria == "Estagiário").scalar()

    # Empresas
    empresas = db.query(models.Empresa).all()
    empresas_data = []
    for e in empresas:
        count = db.query(func.count(models.Funcionario.id)).filter(models.Funcionario.empresa_id == e.id).scalar()
        empresas_data.append({"id": e.id, "razao_social": e.razao_social, "cnpj": e.cnpj, "total_funcionarios": count})

    # Funcionários por categoria
    cats = db.query(models.Funcionario.categoria, func.count(models.Funcionario.id)).group_by(models.Funcionario.categoria).all()

    # Funcionários por setor
    setores = db.query(models.Funcionario.setor, func.count(models.Funcionario.id)).group_by(models.Funcionario.setor).all()

    # Admissões por ano
    admissoes = db.query(
        extract("year", models.Funcionario.data_admissao).label("ano"),
        func.count(models.Funcionario.id)
    ).group_by("ano").order_by("ano").all()

    # Ajustes pendentes
    ajustes_pendentes = db.query(func.count(models.SolicitacaoAjuste.id)).filter(models.SolicitacaoAjuste.status == "Pendente").scalar()

    return {
        "total_funcionarios": total,
        "ativos": ativos,
        "demitidos": demitidos,
        "estagiarios": estagiarios,
        "empresas": empresas_data,
        "por_categoria": [{"categoria": c, "total": t} for c, t in cats],
        "por_setor": [{"setor": s, "total": t} for s, t in setores],
        "admissoes_por_ano": [{"ano": int(a), "total": t} for a, t in admissoes],
        "ajustes_pendentes": ajustes_pendentes,
    }

# ─── Funcionários (com paginação, busca e filtros) ─────────

@app.get("/api/{system}/funcionarios")
def list_funcionarios(
    system: str,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    status: Optional[str] = None,
    categoria: Optional[str] = None,
    setor: Optional[str] = None,
    empresa_id: Optional[int] = None,
    db: Session = Depends(_resolve_db),
):
    q = db.query(models.Funcionario)

    if search:
        q = q.filter(or_(
            models.Funcionario.nome.ilike(f"%{search}%"),
            models.Funcionario.cpf.ilike(f"%{search}%"),
        ))
    if status:
        q = q.filter(models.Funcionario.status == status)
    if categoria:
        q = q.filter(models.Funcionario.categoria == categoria)
    if setor:
        q = q.filter(models.Funcionario.setor == setor)
    if empresa_id:
        q = q.filter(models.Funcionario.empresa_id == empresa_id)

    total = q.count()
    items = q.order_by(models.Funcionario.nome).offset((page - 1) * per_page).limit(per_page).all()

    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "pages": (total + per_page - 1) // per_page,
        "items": [
            {
                "id": f.id,
                "nome": f.nome,
                "cpf": f.cpf,
                "data_nascimento": f.data_nascimento,
                "data_admissao": f.data_admissao,
                "data_demissao": f.data_demissao,
                "setor": f.setor,
                "departamento": f.departamento,
                "cargo": f.cargo,
                "categoria": f.categoria,
                "salario": float(f.salario),
                "status": f.status,
                "empresa_id": f.empresa_id,
            }
            for f in items
        ],
    }

# ─── Detalhe do funcionário ────────────────────────────────

@app.get("/api/{system}/funcionarios/{func_id}")
def get_funcionario(system: str, func_id: int, db: Session = Depends(_resolve_db)):
    f = db.query(models.Funcionario).filter(models.Funcionario.id == func_id).first()
    if not f:
        raise HTTPException(404, "Funcionário não encontrado")

    empresa = db.query(models.Empresa).filter(models.Empresa.id == f.empresa_id).first()

    return {
        "id": f.id,
        "nome": f.nome,
        "cpf": f.cpf,
        "data_nascimento": f.data_nascimento,
        "data_admissao": f.data_admissao,
        "data_demissao": f.data_demissao,
        "setor": f.setor,
        "departamento": f.departamento,
        "cargo": f.cargo,
        "categoria": f.categoria,
        "salario": float(f.salario),
        "status": f.status,
        "empresa": {"id": empresa.id, "razao_social": empresa.razao_social, "cnpj": empresa.cnpj} if empresa else None,
    }

# ─── Apontamentos de um funcionário ────────────────────────

@app.get("/api/{system}/funcionarios/{func_id}/apontamentos")
def get_apontamentos(
    system: str,
    func_id: int,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    data_inicio: Optional[date] = None,
    data_fim: Optional[date] = None,
    db: Session = Depends(_resolve_db),
):
    q = db.query(models.Apontamento).filter(models.Apontamento.funcionario_id == func_id)
    if data_inicio:
        q = q.filter(cast(models.Apontamento.data_hora, Date) >= data_inicio)
    if data_fim:
        q = q.filter(cast(models.Apontamento.data_hora, Date) <= data_fim)

    total = q.count()
    items = q.order_by(desc(models.Apontamento.data_hora)).offset((page - 1) * per_page).limit(per_page).all()

    return {
        "total": total, "page": page, "per_page": per_page,
        "pages": (total + per_page - 1) // per_page,
        "items": [{"id": a.id, "data_hora": a.data_hora, "tipo": a.tipo} for a in items],
    }

# ─── Férias de um funcionário ──────────────────────────────

@app.get("/api/{system}/funcionarios/{func_id}/ferias")
def get_ferias(system: str, func_id: int, db: Session = Depends(_resolve_db)):
    items = db.query(models.Ferias).filter(models.Ferias.funcionario_id == func_id).order_by(desc(models.Ferias.data_inicio)).all()
    return [{"id": f.id, "data_inicio": f.data_inicio, "data_fim": f.data_fim} for f in items]

# ─── Solicitações de ajuste de um funcionário ──────────────

@app.get("/api/{system}/funcionarios/{func_id}/ajustes")
def get_ajustes(
    system: str,
    func_id: int,
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=50),
    db: Session = Depends(_resolve_db),
):
    q = db.query(models.SolicitacaoAjuste).filter(models.SolicitacaoAjuste.funcionario_id == func_id)
    total = q.count()
    items = q.order_by(desc(models.SolicitacaoAjuste.data_solicitacao)).offset((page - 1) * per_page).limit(per_page).all()
    return {
        "total": total, "page": page, "per_page": per_page,
        "pages": (total + per_page - 1) // per_page,
        "items": [
            {"id": a.id, "data_solicitacao": a.data_solicitacao, "data_hora_ajuste": a.data_hora_ajuste, "motivo": a.motivo, "status": a.status}
            for a in items
        ],
    }

# ─── Solicitações de ajuste (todas, para tela dedicada) ───

@app.get("/api/{system}/ajustes")
def list_ajustes(
    system: str,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    status_filter: Optional[str] = None,
    db: Session = Depends(_resolve_db),
):
    q = db.query(models.SolicitacaoAjuste).join(models.Funcionario)
    if status_filter:
        q = q.filter(models.SolicitacaoAjuste.status == status_filter)

    total = q.count()
    items = q.order_by(desc(models.SolicitacaoAjuste.data_solicitacao)).offset((page - 1) * per_page).limit(per_page).all()

    result = []
    for a in items:
        func = db.query(models.Funcionario).filter(models.Funcionario.id == a.funcionario_id).first()
        result.append({
            "id": a.id,
            "funcionario_id": a.funcionario_id,
            "funcionario_nome": func.nome if func else "N/A",
            "data_solicitacao": a.data_solicitacao,
            "data_hora_ajuste": a.data_hora_ajuste,
            "motivo": a.motivo,
            "status": a.status,
        })

    return {"total": total, "page": page, "per_page": per_page, "pages": (total + per_page - 1) // per_page, "items": result}

# ─── Férias (todas, para tela dedicada) ────────────────────

@app.get("/api/{system}/ferias")
def list_ferias(
    system: str,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: Session = Depends(_resolve_db),
):
    q = db.query(models.Ferias).join(models.Funcionario)
    total = q.count()
    items = q.order_by(desc(models.Ferias.data_inicio)).offset((page - 1) * per_page).limit(per_page).all()

    result = []
    for f in items:
        func = db.query(models.Funcionario).filter(models.Funcionario.id == f.funcionario_id).first()
        result.append({
            "id": f.id,
            "funcionario_id": f.funcionario_id,
            "funcionario_nome": func.nome if func else "N/A",
            "data_inicio": f.data_inicio,
            "data_fim": f.data_fim,
        })

    return {"total": total, "page": page, "per_page": per_page, "pages": (total + per_page - 1) // per_page, "items": result}
