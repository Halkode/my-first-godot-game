# Survival Horror Top-Down — Análise Técnica e Roadmap

Inspiração: Darkwood (visual/atmosfera), Project Zomboid (sistemas de sobrevivência/ferimentos), This War of Mine (tom/decisões).
Foco: sobrevivência, exploração, gerenciamento de recursos, sistema médico detalhado. Combate é secundário.

---

## 1. Análise de Tempo de Desenvolvimento (solo + IA)

Estimativas realistas para 1 dev usando IA como acelerador (Godot 4.x, GDScript):

| Sistema | Complexidade | Tempo estimado |
|---|---|---|
| Movimento + colisão + câmera top-down | Baixa | 1-2 semanas (já existe base) |
| Inventário + itens | Média | 2-3 semanas (já existe base parcial) |
| Sistema de ferimentos (dados) | Média-Alta | 3-4 semanas |
| Minigames de tratamento (bandagem, sutura, etc.) | Alta | 4-6 semanas (1-2 sem por minigame) |
| Sangramento/infecção/febre (simulação contínua) | Média-Alta | 2-3 semanas |
| Dia/Noite + iluminação (já existe base) | Baixa | 1 semana de ajuste |
| IA básica de inimigos | Média | 2-3 semanas |
| Construção de abrigo (básico) | Média | 2-3 semanas |
| Save/Load | Média | 1-2 semanas |
| UI/UX geral | Média-Alta | contínuo, 3-4 semanas acumuladas |
| Polimento, balanceamento, bugs | Alta | 4-6 semanas |

**Total MVP realista: 5-8 meses** trabalhando part-time (10-15h/semana), ou **2-3 meses** em ritmo full-time dedicado. O sistema médico com minigames é o maior consumidor de tempo — recomendo implementar **1 minigame completo (bandagem)** primeiro como prova de conceito antes de generalizar para os outros.

---

## 2. Curva de Aprendizado

- **GDScript**: curva suave, você já tem uma base funcional no projeto (autoloads, scenes, scripts organizados).
- **State Machines** (para ferimentos, IA, animações): conceito novo mas essencial — precisa ser aprendido cedo, pois todo o sistema médico depende disso.
- **Minigames de input** (drag, hold, timing): requer entender `Control` nodes, `Input` events, `Tween`/`AnimationPlayer` para feedback visual. Moderado.
- **Sistemas de dados orientados a recursos** (`Resource`/`.tres` para definir ferimentos, itens, receitas): você já usa isso (`recipe.gd`, `ingredient.gd`, `dungeon_tileset.tres`) — é o padrão certo a expandir.
- **Maior risco de curva**: integração entre muitos sistemas (saúde afeta movimento, movimento afeta stamina, stamina afeta saúde...). Mitigar com **sinais (signals)** desacoplados desde o início.

---

## 3. Facilidade para IA Auxiliar Programação

Pontos fortes do seu projeto atual para trabalhar bem com IA:
- Já segue separação por pastas (`scripts/items/`, `scenes/items/`) — manter esse padrão facilita a IA localizar contexto.
- Autoloads (Managers) já estabelecidos — é o padrão ideal: cada sistema novo vira `XManager` autoload com API clara (`apply_damage()`, `start_treatment()`, etc.), e a IA consegue gerar/editar managers isolados sem quebrar o resto.
- **Recomendação**: definir ferimentos, itens médicos e receitas como `Resource` (.tres/.gd com `class_name`) em vez de dicionários soltos — IA gera/edita dados estruturados com muito mais precisão e menos erros de digitação de chaves.
- Minigames são os mais difíceis para IA gerar "de uma vez" (envolvem tuning visual/sensação). Trate-os como protótipos: peça à IA a lógica/estrutura, e ajuste manualmente os "feels" (velocidades, tolerâncias).
- Escrever testes simples em GDScript (ou cenas de teste isoladas) para cada sistema médico ajuda muito a IA verificar regressões.

---

## 4. Performance para Jogos Top-Down

- Godot 4.x com renderer "Forward Plus" (já configurado) é mais que suficiente para 2D top-down.
- **Iluminação**: você já tem `lighting_system.gd`. Para clima Darkwood (escuro, luzes pontuais), use `CanvasModulate` + `Light2D` com poucos lights dinâmicos por vez (oclusão de luz com `LightOccluder2D` tem custo, mas é gerenciável em mapas pequenos/médios).
- **Sistema médico/estado de saúde**: roda em "ticks" (ex: a cada 1s, não a cada frame) via `Timer` — sangramento, febre, infecção não precisam de `_process` por frame. Isso é crítico para performance e escalabilidade.
- **Minigames**: são telas isoladas (provavelmente uma `Control`/scene separada que pausa o jogo) — não impactam performance do mundo.
- **IA de inimigos**: usar `NavigationAgent2D` (built-in) é leve; evite pathfinding customizado complexo no início. Limitar quantidade de inimigos ativos simultaneamente com "pooling"/ativação por proximidade.
- Conclusão: nenhuma preocupação séria de performance no MVP. Atenção futura: muitos `Light2D` + partículas (sangue, fumaça) simultâneas — usar `GPUParticles2D` com limites de quantidade.

---

## 5. Roadmap Completo de Desenvolvimento

### Fase 0 — Fundamentos (já parcialmente feito)
- [x] Movimento, câmera, tilemap, dia/noite, inventário básico, autoloads.
- [ ] Refatorar/auditar autoloads existentes para os novos sistemas (ver seção 6).

### Fase 1 — Núcleo de Sobrevivência
- [ ] `HealthManager`: dados de status do personagem (HP geral, fome, sede, temperatura, sanidade opcional).
- [ ] `BodyPartData` (Resource): estrutura para cada parte do corpo (cabeça, torso, braço E/D, perna E/D) com lista de `Injury`.
- [ ] `Injury` (Resource): tipo (corte raso/profundo, queimadura, fratura, infecção), severidade, sangramento, dor, status de tratamento.
- [ ] Sistema de tick (Timer global) que aplica efeitos contínuos: sangramento reduz HP, dor reduz stamina, febre reduz regeneração.
- [ ] HUD básico: barras de vida, sangramento, dor, temperatura.

### Fase 2 — Sistema Médico (núcleo do jogo)
- [ ] Tela de tratamento (`TreatmentScreen`): visual do corpo (boneco simplificado), clicável por parte.
- [ ] Minigame 1: **Bandagem** (enrolar — input de arrasto circular/sequencial). Afeta sangramento, infecção, recuperação.
- [ ] Minigame 2: **Limpeza de ferida** (remover sujeira/estilhaços — clicar/arrastar sobre pontos).
- [ ] Minigame 3: **Sutura** (pontos — sequência de cliques com timing).
- [ ] Minigame 4: **Tala para fratura** (posicionar + amarrar — combinação de drag + timing).
- [ ] Minigame 5: **Tratamento de queimadura** (aplicar pomada/resfriar — minigame de "spread"/cobertura de área).
- [ ] Sistema de medicamentos (analgésicos, antibióticos, antitérmicos) com efeitos temporizados e riscos (overdose, dependência opcional).
- [ ] Sistema de infecção: chance baseada em qualidade do tratamento + tempo sem cuidado; progride para febre/sepse se ignorada.

### Fase 3 — Mundo e Perigos
- [ ] IA básica de inimigos: patrulha, detecção, ataque simples (causa ferimentos específicos: mordida = corte+infecção alta, etc.).
- [ ] Armadilhas/perigos ambientais (quedas = fratura, fogo = queimadura, vidro = corte).
- [ ] Loot/exploração: containers com itens médicos, comida, materiais de construção.

### Fase 4 — Abrigo e Construção
- [ ] Sistema de construção básico (paredes, porta, cama, fogueira/fogão).
- [ ] Cama = recuperação acelerada e local seguro para tratamentos longos.
- [ ] Estação de crafting médico (produzir bandagens, ferver água, etc.) — já há base em `crafting_manager.gd`.

### Fase 5 — Persistência e Ciclo
- [ ] Save/Load completo (estado do mundo, inventário, ferimentos, tempo).
- [ ] Sistema dia/noite influenciando perigo (inimigos mais ativos à noite — já há base).
- [ ] Eventos narrativos/memórias (já existe `narrative_manager.gd`) — integrar com estado de saúde (alucinações por febre alta, etc.).

### Fase 6 — Polimento
- [ ] Balanceamento de taxas (sangramento, fome, infecção).
- [ ] Áudio reativo (gemidos de dor, batimento cardíaco em estado crítico — `audio_manager.gd` já existe).
- [ ] Tutorial/onboarding do sistema médico.
- [ ] Testes de playtesting e ajustes finais.

---

## 6. Arquitetura de Código

Manter o padrão de **Autoloads (Managers) + Resources (dados) + Scenes (apresentação)** já usado no projeto.

```
Autoloads (singletons, lógica global):
- GameManager        → estado geral do jogo, save/load orquestração
- InventoryManager    → (existe) itens do jogador
- ItemManager         → (existe) definições/instâncias de itens
- CraftingManager      → (existe) receitas
- DayNightCycle        → (existe)
- AudioManager          → (existe)
- NarrativeManager       → (existe)
- UIManager               → (existe) navegação entre telas/HUD
- HealthManager (NOVO)     → estado de saúde do jogador, partes do corpo, ferimentos, ticks de status
- TreatmentManager (NOVO)   → orquestra minigames de tratamento, aplica resultados ao HealthManager
- BuildingManager (NOVO)     → (Fase 4) construção de abrigo
- CombatSystem        → (existe) simplificar — combate é secundário, focar em "aplicar dano/ferimento"
```

Padrão de comunicação: **signals**. Ex.: `HealthManager.injury_added(part, injury)`, `TreatmentManager.treatment_completed(part, injury, quality)` → `HealthManager.apply_treatment_result(...)`.

Dados como `Resource` (class_name) para fácil edição em `.tres` e geração por IA:
```gdscript
# scripts/health/injury.gd
class_name Injury
extends Resource

enum Type { CUT_SHALLOW, CUT_DEEP, BURN, FRACTURE, INFECTION }

@export var type: Type
@export var severity: float       # 0.0 - 1.0
@export var bleeding_rate: float
@export var pain: float
@export var infection_chance: float
@export var treated: bool = false
@export var treatment_quality: float = 0.0
```

---

## 7. Estrutura de Pastas (proposta, expandindo a atual)

```
res://
├── scenes/
│   ├── player.tscn (existe)
│   ├── main.tscn / basement.tscn (existe)
│   ├── ui/
│   │   ├── UI.tscn (existe → mover para cá)
│   │   ├── treatment_screen.tscn (NOVO)
│   │   └── minigames/
│   │       ├── bandage_minigame.tscn (NOVO)
│   │       ├── suture_minigame.tscn (NOVO)
│   │       ├── splint_minigame.tscn (NOVO)
│   │       ├── wound_cleaning_minigame.tscn (NOVO)
│   │       └── burn_treatment_minigame.tscn (NOVO)
│   ├── enemies/ (NOVO)
│   │   └── basic_enemy.tscn
│   ├── building/ (NOVO)
│   │   └── wall_piece.tscn, door_piece.tscn, etc.
│   └── items/ (existe — manter)
│
├── scripts/
│   ├── health/ (NOVO)
│   │   ├── health_manager.gd (autoload)
│   │   ├── injury.gd (Resource)
│   │   ├── body_part.gd (Resource)
│   │   └── status_effects.gd (febre, dor, choque)
│   ├── treatment/ (NOVO)
│   │   ├── treatment_manager.gd (autoload)
│   │   └── minigames/
│   │       ├── bandage_minigame.gd
│   │       ├── suture_minigame.gd
│   │       └── ...
│   ├── enemies/ (NOVO)
│   │   └── basic_enemy_ai.gd
│   ├── building/ (NOVO)
│   │   └── building_manager.gd
│   ├── items/ (existe)
│   ├── ui/ (NOVO — mover ui_manager.gd para cá)
│   ├── player.gd (existe)
│   ├── inventory_manager.gd (existe)
│   ├── crafting_manager.gd (existe)
│   ├── day_night_cycle.gd (existe)
│   ├── lighting_system.gd (existe)
│   ├── audio_manager.gd (existe)
│   ├── narrative_manager.gd (existe)
│   └── game_manager.gd (existe)
│
├── data/ (NOVO — Resources .tres)
│   ├── injuries/
│   ├── medical_items/
│   └── recipes/ (mover de onde estiver)
│
└── assets/ (existe)
```

---

## 8. Tarefas para Execução Incremental (backlog priorizado)

Cada item é uma "tarefa de IA" pequena e testável isoladamente.

**Sprint 1 — Fundação de Saúde**
1. Criar `Injury` e `BodyPart` como Resources.
2. Criar `HealthManager` autoload com lista de `BodyPart` para o player (cabeça, torso, braço E/D, perna E/D).
3. Função `HealthManager.add_injury(part, injury)` + signal `injury_added`.
4. Timer de tick (1s) aplicando sangramento → redução de HP, e dor → redução de stamina/velocidade (`movement_utils.gd`).
5. HUD simples mostrando HP total, sangramento atual, dor.

**Sprint 2 — Tela de Tratamento**
6. Cena `treatment_screen.tscn`: boneco com partes clicáveis (usar `TextureButton`/`Area2D` em `Control`).
7. Ao clicar parte ferida, mostrar lista de ferimentos + itens disponíveis no inventário aplicáveis.
8. `TreatmentManager` autoload: API `start_treatment(part, injury, item)`.

**Sprint 3 — Minigame de Bandagem (protótipo)**
9. Cena `bandage_minigame.tscn`: representação visual do membro + indicador circular.
10. Mecânica: jogador segura e arrasta em movimento circular para "enrolar"; medir cobertura (%) e uniformidade.
11. Resultado (qualidade 0-1) → `TreatmentManager.complete_treatment(quality)` → reduz `bleeding_rate`, define `treatment_quality` no `Injury`, ajusta `infection_chance`.
12. Conectar item "Bandagem"/"Gaze" do inventário para consumir ao usar.

**Sprint 4 — Infecção e Febre**
13. Sistema de chance de infecção baseado em `infection_chance` + tempo sem tratamento (rolagem periódica).
14. Status "Infectado" → febre crescente → afeta stamina/visão (efeito de pós-processamento leve).
15. Item "Antibiótico" reduz infecção ao longo de dias.

**Sprint 5 — Mais Minigames**
16. Minigame de limpeza de ferida (remover estilhaços).
17. Minigame de sutura.
18. Minigame de tala (fratura).
19. Minigame de queimadura.

**Sprint 6 — Perigos e Causas de Ferimento**
20. Função genérica `apply_injury_from_source(source_type, part)` chamada por: ataque de inimigo, queda, fogo, vidro quebrado.
21. IA básica de inimigo (patrulha + ataque simples) usando `NavigationAgent2D`.

**Sprint 7 — Abrigo**
22. `BuildingManager`: colocação de peças simples (parede, porta, cama, fogueira) em grid.
23. Cama acelera recuperação; fogueira fornece calor (combate hipotermia, futuro).

**Sprint 8 — Persistência**
24. Save/Load de: posição do player, inventário, `HealthManager` (todos os `Injury`/`BodyPart`), tempo do dia, estado do mundo (itens coletados, construções).

**Sprint 9 — Polimento MVP**
25. Balancear taxas (testar: quanto tempo até morte por sangramento sem tratamento, etc.).
26. Feedback de áudio/visual para estados críticos (choque, dor extrema).
27. Tutorial inicial guiando o primeiro tratamento.

---

## Recomendação de Próximo Passo

Começar pelo **Sprint 1 + Sprint 2 + minigame de bandagem (Sprint 3)** como vertical slice completo — isso valida a mecânica central do jogo (o diferencial) antes de investir em mais conteúdo. Posso começar a implementar o Sprint 1 agora se quiser.
