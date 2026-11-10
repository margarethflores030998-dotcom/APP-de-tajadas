import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ====== Datos de la microempresa ======
const businessName = 'Tajaderia La Familia';
const businessSlogan = 'Bolsitas de tajadas listas para disfrutar';
const currency = 'C\$';
const whatsappNumber = '50584686130';
const logoPath = 'assets/logo.png';
// ======================================

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
  final String image;
  const Product(
      this.name, this.description, this.emoji, this.price, this.image);
}

// Catálogo: edita nombres, precios y fotos aquí
const catalog = [
  Product('Tajadas Naturales', 'Plátano verde frito con sal. Bolsita de 50 g.',
      '🍌', 15, 'assets/productos/naturales.png'),
  Product('Tajadas con Limón', 'Crujientes con toque de limón. Bolsita de 50 g.',
      '🍋', 20, 'assets/productos/limon.png'),
  Product('Tajadas Picantes', 'Con chile para los que gustan del picante. 50 g.',
      '🌶️', 20, 'assets/productos/picantes.png'),
  Product('Tajadas Familiares', 'Bolsa grande para compartir. 200 g.', '🛍️',
      70, 'assets/productos/familiares.png'),
  Product('Combo Fiesta', '6 bolsitas surtidas de 50 g.', '🎉', 100,
      'assets/productos/combo.png'),
];

// ---------- Carrito ----------
class Cart extends ChangeNotifier {
  final Map<Product, int> items = {};

  int get count => items.values.fold(0, (a, b) => a + b);

  double get total =>
      items.entries.fold(0.0, (sum, e) => sum + e.key.price * e.value);

  void add(Product p, [int qty = 1]) {
    items[p] = (items[p] ?? 0) + qty;
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

// ---------- Imagen del producto (si falta la foto, muestra el emoji) ----------
class ProductImage extends StatelessWidget {
  final Product product;
  final double width;
  final double height;
  final double radius;

  const ProductImage({
    super.key,
    required this.product,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        product.image,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.primaryContainer,
          alignment: Alignment.center,
          child: Text(product.emoji, style: TextStyle(fontSize: height / 2)),
        ),
      ),
    );
  }
}

// ---------- Casilla de cantidad + botón agregar ----------
class QuantityAdder extends StatefulWidget {
  final Product product;
  final Cart cart;
  const QuantityAdder({super.key, required this.product, required this.cart});

  @override
  State<QuantityAdder> createState() => _QuantityAdderState();
}

class _QuantityAdderState extends State<QuantityAdder> {
  final ctrl = TextEditingController(text: '1');

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void addToCart() {
    final qty = int.tryParse(ctrl.text.trim()) ?? 0;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (qty <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe una cantidad mayor a 0')),
      );
      return;
    }
    widget.cart.add(widget.product, qty);
    messenger.showSnackBar(
      SnackBar(
        content: Text('$qty x ${widget.product.name} agregado'),
        duration: const Duration(seconds: 1),
      ),
    );
    ctrl.text = '1';
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Cant.',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: addToCart,
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('Agregar'),
        ),
      ],
    );
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
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Row(
          children: [
            Image.asset(
              logoPath,
              height: 36,
              errorBuilder: (context, error, stack) =>
                  const Icon(Icons.storefront),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(businessName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
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
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailPage(product: p, cart: cart),
                        ),
                      ),
                      child: ProductImage(product: p, width: 90, height: 90),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(p.description),
                          const SizedBox(height: 4),
                          Text(
                            '$currency${p.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          QuantityAdder(product: p, cart: cart),
                        ],
                      ),
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

// ---------- Pantalla de detalle (foto grande del producto) ----------
class ProductDetailPage extends StatelessWidget {
  final Product product;
  final Cart cart;
  const ProductDetailPage(
      {super.key, required this.product, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        children: [
          ProductImage(
            product: product,
            width: double.infinity,
            height: 320,
            radius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(product.description,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 12),
                Text(
                  '$currency${product.price.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                QuantityAdder(product: product, cart: cart),
              ],
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

  Future<void> sendWhatsApp(String message) async {
    final url = Uri.parse(
        'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}');
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
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
          FilledButton.icon(
            onPressed: () async {
              await sendWhatsApp(message);
              widget.cart.clear();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.send),
            label: const Text('Enviar por WhatsApp'),
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
                  leading: ProductImage(
                      product: e.key, width: 48, height: 48, radius: 8),
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
