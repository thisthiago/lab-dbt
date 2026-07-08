export default function SystemSelector({ onSelect, onLogout }) {
  return (
    <div className="system-selector">
      <div className="system-selector-inner">
        <h1>Selecione o Sistema</h1>
        <p>Escolha qual base de dados deseja consultar nesta sessão.</p>

        <div className="system-cards">
          <div className="system-card" onClick={() => onSelect('admin')}>
            <div className="card-icon" style={{ background: 'var(--accent-muted)', color: 'var(--accent-hover)' }}>🏢</div>
            <h3>Administração</h3>
            <p>Funcionários, estagiários e equipe administrativa de todos os setores</p>
          </div>
          <div className="system-card" onClick={() => onSelect('motoristas')}>
            <div className="card-icon" style={{ background: 'var(--success-muted)', color: 'var(--success)' }}>🚚</div>
            <h3>Motoristas</h3>
            <p>Equipe de logística e transporte — motoristas de todas as empresas</p>
          </div>
        </div>

        <button className="btn btn-ghost" style={{ marginTop: '32px' }} onClick={onLogout}>
          ← Sair da conta
        </button>
      </div>
    </div>
  );
}
