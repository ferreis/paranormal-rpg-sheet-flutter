# Regras de Arquitetura - Flutter / Dart

Este documento define o padrão de organização de pastas, responsabilidade dos arquivos e nomenclatura usada no projeto Flutter.

---

## 1. Arquitetura principal

O projeto deve usar uma arquitetura baseada em **features**.

Cada funcionalidade principal do app deve ficar dentro da pasta `features/`.

Estrutura base recomendada:

```text
lib/
├── main.dart
├── app/
├── core/
├── features/
└── shared/
```

---

## 2. Regras das pastas principais

### `main.dart`

Arquivo inicial do projeto.

Deve ter apenas o necessário para iniciar o app.

Exemplo de responsabilidade:

```dart
void main() {
  runApp(const App());
}
```

Não deve conter regra de negócio, tela grande ou configuração complexa.

---

### `app/`

Pasta responsável pela configuração principal do aplicativo.

Pode conter:

```text
app/
├── app.dart
├── router/
├── theme/
└── dependency_injection/
```

Tipos de arquivos permitidos:

```text
app.dart
app_router.dart
app_theme.dart
app_colors.dart
app_text_styles.dart
injection.dart
```

Responsabilidades:

- Configurar o app principal.
- Configurar rotas.
- Configurar tema.
- Configurar injeção de dependência, se existir.

Não deve conter:

- Tela de feature.
- Requisição HTTP.
- Regra de negócio específica.
- Model de API.

---

### `core/`

Pasta para recursos globais do projeto.

Use somente para código que pode ser usado por várias features.

Pode conter:

```text
core/
├── constants/
├── errors/
├── http/
├── storage/
├── utils/
└── widgets/
```

Tipos de arquivos permitidos:

```text
app_constants.dart
app_exception.dart
failure.dart
http_client.dart
local_storage.dart
date_formatter.dart
app_button.dart
app_input.dart
app_loading.dart
```

Responsabilidades:

- Cliente HTTP global.
- Tratamento de erro global.
- Constantes globais.
- Storage local genérico.
- Widgets reutilizáveis no app todo.
- Funções utilitárias genéricas.

Não deve conter:

- Código específico de uma feature.
- Tela de uma funcionalidade.
- Repository específico.
- UseCase específico.

---

### `features/`

Pasta principal das funcionalidades do app.

Cada funcionalidade deve ter sua própria pasta.

Exemplo:

```text
features/
├── auth/
├── character_sheet/
├── export_pdf/
├── import_pdf/
└── share_sheet/
```

Cada feature deve seguir esta estrutura:

```text
nome_da_feature/
├── data/
├── domain/
└── presentation/
```

---

## 3. Regras internas de cada feature

### `data/`

Pasta responsável por dados externos e implementação técnica.

Pode conter:

```text
data/
├── datasources/
├── models/
└── repositories/
```

Tipos de arquivos permitidos:

```text
auth_remote_datasource.dart
auth_local_datasource.dart
user_model.dart
auth_repository_impl.dart
```

Responsabilidades:

- Buscar dados da API.
- Buscar dados do banco local.
- Ler e salvar dados locais.
- Converter JSON em model.
- Implementar repositories.

Não deve conter:

- Widget.
- Tela.
- Estado visual.
- Regra de UI.

---

### `domain/`

Pasta responsável pela regra de negócio pura.

Pode conter:

```text
domain/
├── entities/
├── repositories/
└── usecases/
```

Tipos de arquivos permitidos:

```text
user.dart
auth_repository.dart
login_user.dart
logout_user.dart
```

Responsabilidades:

- Entidades principais.
- Contratos de repository.
- Casos de uso.
- Regras de negócio.

Não deve conter:

- Código Flutter de UI.
- BuildContext.
- Widget.
- Requisição HTTP direta.
- SharedPreferences direto.
- SQLite direto.

Observação:

Em projeto pequeno, a pasta `domain/` pode ser criada apenas quando a regra de negócio começar a crescer.

---

### `presentation/`

Pasta responsável pela interface e controle visual da feature.

Pode conter:

```text
presentation/
├── pages/
├── widgets/
└── controllers/
```

Tipos de arquivos permitidos:

```text
login_page.dart
login_form.dart
auth_controller.dart
character_sheet_page.dart
character_sheet_card.dart
```

Responsabilidades:

- Telas.
- Widgets da feature.
- Controllers.
- Estados da tela.
- Validação visual de formulário.

Não deve conter:

- Requisição HTTP direta.
- SQL.
- Conversão manual de JSON.
- Regra de negócio complexa.

---

## 4. Fluxo recomendado

O fluxo padrão deve ser:

```text
Page / Widget
   ↓
Controller / ViewModel / Cubit / Provider
   ↓
UseCase
   ↓
Repository
   ↓
Datasource
   ↓
API / Banco local / Arquivo / Storage
```

Exemplo de login:

```text
login_page.dart
   ↓
auth_controller.dart
   ↓
login_user.dart
   ↓
auth_repository.dart
   ↓
auth_repository_impl.dart
   ↓
auth_remote_datasource.dart
```

---

## 5. Exemplo completo de estrutura

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   └── dependency_injection/
│       └── injection.dart
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── app_exception.dart
│   │   └── failure.dart
│   ├── http/
│   │   └── http_client.dart
│   ├── storage/
│   │   └── local_storage.dart
│   ├── utils/
│   │   └── date_formatter.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_input.dart
│       └── app_loading.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_user.dart
│   │   │       └── logout_user.dart
│   │   │
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       ├── widgets/
│   │       │   └── login_form.dart
│   │       └── controllers/
│   │           └── auth_controller.dart
│   │
│   └── character_sheet/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── shared/
    ├── enums/
    ├── extensions/
    └── validators/
```

---

# Padrão de Nomenclatura - Flutter / Dart

## 1. Arquivos e pastas

Formato obrigatório:

```text
snake_case
```

Regra:

- Usar letras minúsculas.
- Separar palavras com `_`.
- Máximo de 3 palavras.
- Recomendado: 2 palavras.
- O nome deve explicar a responsabilidade do arquivo.

Exemplos corretos:

```text
home_screen.dart
botao_salvar.dart
usuario_service.dart
auth_controller.dart
login_page.dart
user_model.dart
```

Exemplos incorretos:

```text
HomeScreen.dart
botaoSalvar.dart
usuario.service.dart
arquivo.dart
coisa.dart
tela.dart
```

---

## 2. Classes e widgets

Formato obrigatório:

```text
PascalCase
```

Regra:

- Cada palavra começa com letra maiúscula.
- Não usar `_`.
- Máximo de 3 palavras.
- Recomendado: 2 palavras.
- O nome deve representar claramente o componente ou classe.

Exemplos corretos:

```dart
class HomeScreen {}
class BotaoSalvar {}
class UsuarioCard {}
class AuthController {}
class UserModel {}
```

Exemplos incorretos:

```dart
class homeScreen {}
class botao_salvar {}
class Usuario {}
class Tela {}
class Coisa {}
```

---

## 3. Funções e métodos

Formato obrigatório:

```text
camelCase
```

Regra:

- Primeira palavra começa com letra minúscula.
- Próximas palavras começam com letra maiúscula.
- Máximo de 2 palavras.
- Recomendado: 2 palavras.
- O nome deve iniciar com verbo quando representar uma ação.

Exemplos corretos:

```dart
void salvarDados() {}
void buscarUsuario() {}
void autenticar() {}
void exportarPdf() {}
void importarFicha() {}
```

Exemplos incorretos:

```dart
void SalvarDados() {}
void salvar_dados() {}
void dados() {}
void fazer() {}
void executarProcessoDeLoginDoUsuario() {}
```

---

## 4. Variáveis e parâmetros

Formato obrigatório:

```text
camelCase
```

Regra:

- Primeira palavra começa com letra minúscula.
- Próximas palavras começam com letra maiúscula.
- Máximo de 3 palavras.
- Recomendado: 2 palavras.
- O nome deve deixar claro o valor armazenado.
- Não usar nome de variável com apenas 1 caractere.

Exemplos corretos:

```dart
String nomeUsuario;
int totalItens;
double precoFinal;
bool usuarioLogado;
List<String> nomesArquivos;
```

Exemplos incorretos:

```dart
String n;
int x;
double p;
bool flag;
var data;
```

---

## 5. Regras gerais de nomes

Evitar nomes genéricos:

```text
data
item
value
temp
teste
coisa
arquivo
manager
helper
utils
```

Preferir nomes claros:

```text
dadosUsuario
itemSelecionado
valorTotal
arquivoFicha
authController
pdfExportService
```

---

## 6. Sufixos recomendados por tipo de arquivo

Use sufixos para deixar claro o papel do arquivo.

### Telas

```text
login_page.dart
home_page.dart
character_sheet_page.dart
```

Classe:

```dart
class LoginPage {}
class HomePage {}
class CharacterSheetPage {}
```

---

### Widgets

```text
login_form.dart
user_card.dart
app_button.dart
```

Classe:

```dart
class LoginForm {}
class UserCard {}
class AppButton {}
```

---

### Controllers

```text
auth_controller.dart
sheet_controller.dart
pdf_controller.dart
```

Classe:

```dart
class AuthController {}
class SheetController {}
class PdfController {}
```

---

### Models

```text
user_model.dart
sheet_model.dart
attribute_model.dart
```

Classe:

```dart
class UserModel {}
class SheetModel {}
class AttributeModel {}
```

---

### Entities

```text
user.dart
character_sheet.dart
attribute.dart
```

Classe:

```dart
class User {}
class CharacterSheet {}
class Attribute {}
```

---

### Repositories

Contrato:

```text
auth_repository.dart
sheet_repository.dart
```

Implementação:

```text
auth_repository_impl.dart
sheet_repository_impl.dart
```

Classes:

```dart
abstract class AuthRepository {}
class AuthRepositoryImpl implements AuthRepository {}
```

---

### Datasources

```text
auth_remote_datasource.dart
sheet_local_datasource.dart
pdf_file_datasource.dart
```

Classes:

```dart
class AuthRemoteDatasource {}
class SheetLocalDatasource {}
class PdfFileDatasource {}
```

---

### UseCases

```text
login_user.dart
logout_user.dart
export_sheet.dart
import_sheet.dart
```

Classes:

```dart
class LoginUser {}
class LogoutUser {}
class ExportSheet {}
class ImportSheet {}
```

---

### Services

Use `service` somente quando o arquivo representa uma integração ou serviço técnico.

```text
pdf_export_service.dart
qr_code_service.dart
share_service.dart
```

Classes:

```dart
class PdfExportService {}
class QrCodeService {}
class ShareService {}
```

---

## 7. Regras para imports

Preferir imports organizados nesta ordem:

```dart
// Dart
import 'dart:io';

// Packages
import 'package:flutter/material.dart';

// Projeto
import 'package:nome_do_app/core/widgets/app_button.dart';
import 'package:nome_do_app/features/auth/domain/entities/user.dart';
```

Regra:

- Primeiro imports do Dart.
- Depois imports de packages externos.
- Depois imports do próprio projeto.
- Evitar imports relativos muito longos.

Evitar:

```dart
import '../../../core/widgets/app_button.dart';
```

Preferir:

```dart
import 'package:nome_do_app/core/widgets/app_button.dart';
```

---

## 8. Regras para widgets

Widgets devem ser pequenos e claros.

Se o método `build` ficar grande, separar em widgets menores.

Exemplo:

```text
login_page.dart
login_form.dart
login_button.dart
```

Evitar criar vários métodos privados grandes dentro da tela:

```dart
Widget _buildHeader() {}
Widget _buildForm() {}
Widget _buildButton() {}
```

Preferir widgets separados quando forem reutilizáveis ou grandes.

---

## 9. Regras para controllers

Controller deve controlar estado e ações da tela.

Pode fazer:

- Chamar UseCase.
- Atualizar estado.
- Controlar loading.
- Controlar erro.
- Controlar sucesso.

Não deve fazer:

- Requisição HTTP direta.
- Converter JSON.
- Ter regra pesada de negócio.
- Montar widget.

---

## 10. Regras para repositories

Repository é a ponte entre `domain` e `data`.

Contrato fica em:

```text
domain/repositories/
```

Implementação fica em:

```text
data/repositories/
```

Exemplo:

```text
domain/repositories/auth_repository.dart
data/repositories/auth_repository_impl.dart
```

---

## 11. Regras para datasources

Datasource acessa a fonte real dos dados.

Exemplos:

```text
auth_remote_datasource.dart
sheet_local_datasource.dart
pdf_file_datasource.dart
```

Pode acessar:

- API.
- SQLite.
- SharedPreferences.
- Arquivos.
- PDF.
- Bluetooth.
- QR Code.

Não deve conter regra visual ou widget.

---

## 12. Regra final

Antes de criar um arquivo novo, responder:

```text
Esse arquivo pertence a qual feature?
Esse arquivo é tela, widget, controller, usecase, repository, datasource ou model?
Esse arquivo será usado por várias features?
```

Se for usado por várias features, considerar colocar em:

```text
core/
```

ou

```text
shared/
```

Se for específico de uma funcionalidade, colocar em:

```text
features/nome_da_feature/
```
