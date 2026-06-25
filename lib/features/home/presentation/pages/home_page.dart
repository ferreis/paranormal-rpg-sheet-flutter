import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<SheetArea> sheetAreas = [
    SheetArea(
      icon: Icons.person_outline,
      title: 'Personagem',
      description: 'Dados principais, origem, classe e trilha.',
    ),
    SheetArea(
      icon: Icons.insights_outlined,
      title: 'Atributos',
      description: 'Força, agilidade, intelecto, presença e vigor.',
    ),
    SheetArea(
      icon: Icons.checklist_outlined,
      title: 'Perícias',
      description: 'Treinamento, bônus e testes calculados.',
    ),
    SheetArea(
      icon: Icons.shield_outlined,
      title: 'Combate',
      description: 'PV, sanidade, PE, defesa, dano e resistências.',
    ),
    SheetArea(
      icon: Icons.backpack_outlined,
      title: 'Inventário',
      description: 'Itens, armas, proteções e carga.',
    ),
    SheetArea(
      icon: Icons.casino_outlined,
      title: 'Rolagens',
      description: 'Dados e modificadores prontos para uso offline.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Fichas Ordem')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Fichas de Ordem Paranormal',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'App offline para criar, calcular e consultar fichas de RPG.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Nova ficha'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Minhas fichas'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Módulos da ficha',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool useTwoColumns = constraints.maxWidth >= 560;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sheetAreas.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: useTwoColumns ? 2 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: useTwoColumns ? 2.35 : 3.4,
                  ),
                  itemBuilder: (BuildContext context, int sheetAreaIndex) {
                    final SheetArea sheetArea = sheetAreas[sheetAreaIndex];

                    return SheetAreaCard(sheetArea: sheetArea);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SheetArea {
  const SheetArea({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class SheetAreaCard extends StatelessWidget {
  const SheetAreaCard({required this.sheetArea, super.key});

  final SheetArea sheetArea;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(sheetArea.icon, color: colorScheme.primary, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sheetArea.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sheetArea.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
