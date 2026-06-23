# Fichas Ordem

App Flutter offline para criar, calcular e consultar fichas de RPG de Ordem Paranormal no Android.

## Stack

- Flutter 3.44.x
- Dart 3.12.x
- Android

## Rodar localmente

```bash
flutter pub get
flutter run
```

## Rodar testes

```bash
flutter test
```

## Escopo inicial

- Fichas salvas offline.
- Calculo automatico de atributos, pericias, defesa, vida, sanidade e PE.
- Inventario.
- Suporte inicial focado em Android.

## Estrutura criada

- `lib/core/database/app_database.dart`: abertura do SQLite e schema.
- `lib/features/characters/data/models/character_sheet.dart`: modelos da ficha.
- `lib/features/characters/data/repositories/character_repository.dart`: acesso ao banco.
- `lib/features/characters/domain/services/character_calculation_service.dart`: calculos automaticos.
- `lib/features/characters/presentation/controllers/character_editor_controller.dart`: estado da edicao e auto-save.
- `lib/features/characters/presentation/pages/`: telas de lista, detalhe, formulario, edicao e JSON.
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

- Cada ficha usa `id` unico.
- Registros filhos usam `character_id`.
- Exclusao da ficha remove os dados dependentes com `ON DELETE CASCADE`.
- `created_at` e `updated_at` ficam em `characters`.
- Telas nao acessam SQLite diretamente.

## Telas

- `CharacterListPage`: lista fichas, busca por nome, cria, duplica, exclui e importa JSON.
- `CharacterFormPage`: formulario editavel com abas.
- `CharacterDetailPage`: resumo da ficha e acoes principais.
- `CharacterEditPage`: entrada dedicada para edicao.
- `CharacterImportExportPage`: importacao e exportacao por JSON.

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
- Adicionar pericia, arma, item, ritual, poder, habilidade, anotacao e historico.
- Organizar a ficha por abas.

## Calculos automaticos

- Vida maxima = vida base + vigor * vida por vigor + bonus manual.
- Sanidade maxima = sanidade base + presenca * sanidade por presenca + bonus manual.
- Esforco maximo = esforco base + presenca * esforco por presenca + bonus manual.
- Defesa = defesa base + agilidade + bonus de protecoes + bonus manual.
- Valores maximos podem ser editados manualmente por override.
- Vida, sanidade e esforco atuais sao limitados entre zero e o maximo.

## Validacoes feitas

- `flutter analyze`
- `flutter test`
  - calculos automaticos;
  - repository com SQLite em arquivo temporario;
  - salvar, reabrir, listar, duplicar, exportar, importar e excluir ficha;
  - exclusao em cascata dos dados dependentes.
- `flutter build apk --debug`

Build gerado em:

```bash
build/app/outputs/flutter-apk/app-debug.apk
```

## Pendencias futuras

- Melhorar fluxo visual de copiar/compartilhar JSON.
- Adicionar filtros por classe, trilha ou patente.
- Criar backup/restauracao de multiplas fichas em lote.
