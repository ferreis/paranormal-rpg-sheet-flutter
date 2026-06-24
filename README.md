# Fichas Ordem

App Flutter offline para criar, calcular e consultar fichas de RPG de Ordem Paranormal no Android.

## Stack

- Flutter 3.44.x
- Dart 3.12.x
- Android
- SQLite local com `sqflite`
- Importação online opcional via link público do C.R.I.S.

## Rodar localmente

```bash
flutter pub get
flutter run
```

Para usar a importação por link do C.R.I.S., informe a chave em tempo de build:

```bash
flutter run --dart-define=CRIS_FIREBASE_API_KEY=sua_chave
```

## Rodar testes

```bash
flutter test
```

## Escopo inicial

- Fichas salvas offline.
- Cálculo automático de atributos, perícias, defesa, vida, sanidade e PE.
- Inventário.
- Suporte inicial focado em Android.

## Estrutura criada

- `lib/core/database/app_database.dart`: abertura do SQLite e schema.
- `lib/features/characters/data/models/character_sheet.dart`: modelos da ficha.
- `lib/features/characters/data/repositories/character_repository.dart`: acesso ao banco.
- `lib/features/characters/domain/services/character_calculation_service.dart`: cálculos automáticos.
- `lib/features/characters/presentation/controllers/character_editor_controller.dart`: estado da edição e auto-save.
- `lib/features/characters/data/services/cris_character_import_service.dart`: importação de ficha pública do C.R.I.S.
- `lib/features/characters/presentation/pages/`: telas de lista, detalhe, formulário, edição, JSON e importação C.R.I.S.
- `lib/features/characters/presentation/widgets/`: campos, cards, seletor de atributo e status de salvamento.

## Banco SQLite

Tabelas:

- `characters`
- `character_attributes`
- `character_skills`
- `character_weapons`
- `character_items`
- `character_rituals`
- `character_powers`
- `character_notes`

Regras:

- Cada ficha usa `id` único.
- Registros filhos usam `character_id`.
- Exclusão da ficha remove os dados dependentes com `ON DELETE CASCADE`.
- `created_at` e `updated_at` ficam em `characters`.
- Telas não acessam SQLite diretamente.

## Telas

- `CharacterListPage`: lista fichas, busca por nome, cria, duplica, exclui e abre importações.
- `CharacterFormPage`: formulário editável com abas.
- `CharacterDetailPage`: resumo da ficha e ações principais.
- `CharacterEditPage`: entrada dedicada para edição.
- `CharacterImportExportPage`: importação/exportação por JSON e importação por link C.R.I.S.

## Funcionalidades implementadas

- Criar ficha.
- Editar ficha.
- Listar fichas salvas.
- Buscar por nome.
- Excluir ficha.
- Duplicar ficha.
- Auto-save com indicador de status.
- Exportar ficha em JSON.
- Importar ficha por JSON.
- Importar ficha pública do C.R.I.S. por link.
- Adicionar perícia, arma, item, ritual, poder, habilidade, anotação e histórico.
- Organizar a ficha por abas.

Observação:

- A importação C.R.I.S. busca dados públicos da ficha e salva no SQLite local.
- Descrições longas de regras, itens, poderes e rituais não são importadas automaticamente.

## Cálculos automáticos

- Vida máxima = vida base + vigor * vida por vigor + bônus manual.
- Sanidade máxima = sanidade base + presença * sanidade por presença + bônus manual.
- Esforço máximo = esforço base + presença * esforço por presença + bônus manual.
- Defesa = defesa base + agilidade + bônus de proteções + bônus manual.
- Valores máximos podem ser editados manualmente por override.
- Vida, sanidade e esforço atuais são limitados entre zero e o máximo.

## Validações feitas

- `flutter analyze`
- `flutter test`
  - cálculos automáticos;
  - repository com SQLite em arquivo temporário;
  - conversão de ficha C.R.I.S. para o modelo local;
  - salvar, reabrir, listar, duplicar, exportar, importar e excluir ficha;
  - exclusão em cascata dos dados dependentes.
- `flutter build apk --debug`

Build gerado em:

```bash
build/app/outputs/flutter-apk/app-debug.apk
```

## Pendências futuras

- Melhorar fluxo visual de copiar/compartilhar JSON.
- Adicionar filtros por classe, trilha ou patente.
- Criar backup/restauração de múltiplas fichas em lote.
