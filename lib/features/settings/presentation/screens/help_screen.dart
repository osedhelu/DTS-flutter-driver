import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      (
        '¿Cómo recibo pedidos?',
        'Activa el interruptor “En línea” en Inicio y mantén el GPS activo. Las ofertas aparecerán en el mapa y en la hoja inferior.'
      ),
      (
        '¿Qué hago si no encuentro al cliente?',
        'Usa el chat o llama desde la pantalla de entrega activa. Si no hay respuesta, contacta a soporte.'
      ),
      (
        '¿Cuándo cobro?',
        'En Ganancias verás el acumulado del día, semana o mes (10% del total del pedido entregado).'
      ),
      (
        '¿Cómo actualizo mis datos?',
        'Ve a Perfil → Editar perfil o Ajustes → Editar perfil.'
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DtsSectionHeader(
            title: 'Preguntas frecuentes',
            subtitle: 'Guía rápida para conductores DTS',
          ),
          ...faqs.map(
            (faq) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text(faq.$1),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(faq.$2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
