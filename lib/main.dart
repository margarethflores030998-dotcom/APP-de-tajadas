import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ====== Datos de mimicroempresa ======
const businessName = 'Tajaderia La Familia';
const businessSlogan = 'Bolsitas de tajadas listas para disfrutar';
const whatsappNumber = '50584686130';
const currency = 'C\$';
// ===========================================================

void main() => runApp(const TajadasApp());

class TajadasApp extends StatelessWidget {
  const TajadasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: businessName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF2A900)),
      ),
      home: HomePage(),
    );
  }
}

// ---------- Modelo ----------
class Product {
  final String name;
  final String description;
  final String emoji;
  final double price;
  const Product(this.name, this.description, this.emoji, this.price);
}

// Catálogo de ejemplo: edita nombres y precios
const catalog = [
  Product('Tajadas Naturales', 'Plátano verde frito con sal. Bolsita de 50 g.', '🍌', 15),
  Product('Tajadas con Limón', 'Crujientes con toque de limón. Bolsita de 50 g.', '🍋', 20),
  Product('Tajadas Picantes', 'Con chile para los que gustan del picante. 50 g.', '🌶️', 20),
  Product('Tajadas Familiares', 'Bolsa grande para compartir. 200 g.', '🛍️', 70),
  Product('Combo Fiesta', '6 bolsitas surtidas de 50 g.', '🎉', 100),
];

// ---------- Carrito ----------
class Cart extends ChangeNotifier {
  final Map<Product, int> items = {};

  int get count => items.values.fold(0, (a, b) => a + b);

  double get total =>
      items.entries.fold(0.0, (sum, e) => sum + e.key.price * e.value);

  void add(Product p) {
    items[p] = (items[p] ?? 0) + 1;
    notifyListeners();
  }

  void remove(Product p) {
    final qty = items[p] ?? 0;
    if (qty <= 1) {
      items.remove(p);
    } else {
      items[p] = qty - 1;
    }
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }
}

// ---------- Pantalla principal ----------
class HomePage extends StatelessWidget {
  HomePage({super.key});

  final Cart cart = Cart();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(businessName),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Badge(
                isLabelVisible: cart.count > 0,
                label: Text('${cart.count}'),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CartPage(cart: cart)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              businessSlogan,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final p in catalog)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 28,
                  child: Text(p.emoji, style: const TextStyle(fontSize: 28)),
                ),
                title: Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${p.description}\n$currency${p.price.toStringAsFixed(2)}'),
                isThreeLine: true,
                trailing: IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    cart.add(p);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${p.name} agregado'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- Pantalla del carrito ----------
class CartPage extends StatefulWidget {
  final Cart cart;
  const CartPage({super.key, required this.cart});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  String buildMessage() {
    final cart = widget.cart;
    final lines = cart.items.entries
        .map((e) =>
            '• ${e.value} x ${e.key.name} = $currency${(e.key.price * e.value).toStringAsFixed(2)}')
        .join('\n');
    return 'Pedido - $businessName\n'
        'Cliente: ${nameCtrl.text}\n'
        'Teléfono: ${phoneCtrl.text}\n'
        'Dirección: ${addressCtrl.text}\n\n'
        '$lines\n\n'
        'Total: $currency${cart.total.toStringAsFixed(2)}';
  }

  void confirmOrder() {
    if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu nombre y dirección')),
      );
      return;
    }
    final message = buildMessage();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resumen del pedido'),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copiado. Pégalo en WhatsApp')),
              );
            },
            child: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () {
              widget.cart.clear();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu pedido')),
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Tu carrito está vacío'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final e in cart.items.entries)
                ListTile(
                  leading: Text(e.key.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(e.key.name),
                  subtitle: Text(
                      '$currency${(e.key.price * e.value).toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => cart.remove(e.key),
                      ),
                      Text('${e.value}',
                          style: const TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => cart.add(e.key),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Text(
                'Total: $currency${cart.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Teléfono', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                    labelText: 'Dirección de entrega',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: confirmOrder,
                icon: const Icon(Icons.check),
                label: const Text('Confirmar pedido'),
              ),
            ],
          );
        },
      ),
    );
  }
}
