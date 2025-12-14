import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paragalien/models/produit.dart';
import 'package:paragalien/providers/produit_provider.dart';
import 'package:paragalien/views/client/commande_tab.dart';
import 'package:paragalien/views/client/profile_tab.dart';
import 'package:paragalien/views/client/paragalian_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'carousel_widget.dart';

enum ClientTab { produits, commande, profile, paragalian }

class ClientHome extends ConsumerStatefulWidget {
  const ClientHome({super.key});

  @override
  ConsumerState<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends ConsumerState<ClientHome> {
  ClientTab _currentTab = ClientTab.produits;
  String _searchQuery = '';
  User? _currentUser;
  bool _showSearchBar = false;
  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription<AuthState>? _authSubscription;
  bool _cartLoaded = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> productCategories = [
    'Tous les produits',
    'Produits disponibles',
    'Produits en rupture',
    'Complément alimentaire',
    'Article bébé',
    'matériale médicale',
    'antiseptique',
    'dermo cosmetique',
  ];

  final List<CategoryItem> homeCategories = [
    CategoryItem(
      name: 'Premiers Soins',
      icon: Icons.first_aid_kit,
      color: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF2E7D32),
    ),
    CategoryItem(
      name: 'Antiseptiques',
      icon: Icons.cleaning_services,
      color: const Color(0xFFFFF3E0),
      iconColor: const Color(0xFFE65100),
    ),
    CategoryItem(
      name: 'Aromathérapie',
      icon: Icons.local_florist,
      color: const Color(0xFFFCE4EC),
      iconColor: const Color(0xFFC2185B),
    ),
    CategoryItem(
      name: 'Compléments',
      icon: Icons.medical_services,
      color: const Color(0xFFE0F2F1),
      iconColor: const Color(0xFF00695C),
    ),
    CategoryItem(
      name: 'Articles Bébé',
      icon: Icons.child_care,
      color: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1565C0),
    ),
    CategoryItem(
      name: 'Matériel Médical',
      icon: Icons.monitor_heart,
      color: const Color(0xFFF3E5F5),
      iconColor: const Color(0xFF6A1B9A),
    ),
  ];

  String selectedCategory = 'Produits disponibles';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadCartData();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      setState(() {
        _currentUser = event.session?.user;
      });
    });
  }

  Future<void> _loadCartData() async {
    if (!_cartLoaded) {
      await ref.read(selectedProduitsProvider.notifier).loadCart();
      setState(() {
        _cartLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  String formatPrice(double price) {
    if (price % 1 == 0) {
      return price.toStringAsFixed(0);
    } else {
      return price.toStringAsFixed(3);
    }
  }

  bool _matchesSearchQuery(Produit produit, String query) {
    if (query.isEmpty) return true;
    final productName = produit.name.toLowerCase();
    final searchTerms = query.toLowerCase().split(' ');
    return searchTerms.every((term) => productName.contains(term));
  }

  Future<void> _refreshData() async {
    try {
      await ref.refresh(produitsProvider.future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de rafraîchissement: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedProduits = ref.watch(selectedProduitsProvider);
    final cartCount = selectedProduits.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(cartCount),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          if (_currentTab == ClientTab.produits) ...[
            _buildSearchBar(),
            _buildCarousel(),
            _buildCategoriesSection(),
          ],
          Expanded(child: _buildCurrentTab()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(int cartCount) {
    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: SizedBox(
        height: 45,
        width: 45,
        child: Image.asset('assets/icons/logo.png', fit: BoxFit.contain),
      ),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.black87),
              onPressed: () => setState(() => _currentTab = ClientTab.commande),
            ),
            if (cartCount > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cartCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: Image.asset('assets/icons/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ParaGalien',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Accueil'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTab = ClientTab.produits);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Produits'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTab = ClientTab.produits);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Commandes'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTab = ClientTab.commande);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTab = ClientTab.profile);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () {
                Navigator.pop(context);
                Supabase.instance.client.auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
        decoration: InputDecoration(
          hintText: 'Rechercher des produits',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    final carouselItems = [
      CarouselItemData(
        title: 'Complexe Magnésium',
        subtitle: 'Moins de stress, Plus de vitalité',
        color: const Color(0xFFE8F5E9),
        accentColor: const Color(0xFF2E7D32),
      ),
      CarouselItemData(
        title: 'Vitamines & Santé',
        subtitle: 'Renforcez votre immunité',
        color: const Color(0xFFFFF3E0),
        accentColor: const Color(0xFFE65100),
      ),
      CarouselItemData(
        title: 'Premiers Soins',
        subtitle: 'Soins essentiels à portée de main',
        color: const Color(0xFFFCE4EC),
        accentColor: const Color(0xFFC2185B),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CarouselWidget(items: carouselItems),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nos catégories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: homeCategories.length,
              itemBuilder: (context, index) => _buildCategoryCard(homeCategories[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryItem category) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => selectedCategory = category.name),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                category.icon,
                color: category.iconColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case ClientTab.produits:
        return _buildProductsList(ref);
      case ClientTab.commande:
        if (_currentUser == null) {
          return const Center(
            child: Text('Veuillez vous connecter pour passer une commande'),
          );
        }
        return CommandeTab(userId: _currentUser!.id);
      case ClientTab.profile:
        return const ProfileTab();
      case ClientTab.paragalian:
        return const ParagalianPage();
    }
  }

  Widget _buildProductsList(WidgetRef ref) {
    final produitsAsync = ref.watch(produitsProvider);
    final selectedProduits = ref.watch(selectedProduitsProvider);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: produitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (produits) {
          List<Produit> filteredProduits = produits.where((p) {
            if (!_matchesSearchQuery(p, _searchQuery)) {
              return false;
            }

            switch (selectedCategory) {
              case 'Tous les produits':
                return true;
              case 'Produits disponibles':
                return p.quantity > 0;
              case 'Produits en rupture':
                return p.quantity <= 0;
              default:
                return p.category == selectedCategory;
            }
          }).toList();

          if (selectedCategory == 'Produits en rupture') {
            filteredProduits.sort((a, b) => a.quantity.compareTo(b.quantity));
          }

          if (filteredProduits.isEmpty) {
            return ListView(
              children: [
                Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'Aucun produit trouvé pour "$_searchQuery"'
                        : selectedCategory == 'Produits en rupture'
                            ? 'Aucun produit en rupture de stock'
                            : selectedCategory == 'Produits disponibles'
                                ? 'Aucun produit disponible'
                                : 'Aucun produit dans cette catégorie',
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredProduits.length,
            itemBuilder: (context, index) {
              final produit = filteredProduits[index];
              final quantity = selectedProduits
                  .firstWhere(
                    (sp) => sp.produit.id == produit.id,
                    orElse: () => SelectedProduct(produit, 0),
                  )
                  .quantity;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          produit.imageUrl != null
                              ? GestureDetector(
                                  onTap: () => _showEnlargedImage(context, produit.imageUrl!),
                                  child: CachedNetworkImage(
                                    imageUrl: produit.imageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                )
                              : const Icon(Icons.image, size: 80),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produit.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatPrice(produit.price)} DA',
                                  style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PPA: ${produit.ppa}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            produit.quantity > 0 ? 'En stock' : 'Rupture de stock',
                            style: TextStyle(
                              color: produit.quantity > 0 ? Colors.green : Colors.orange,
                            ),
                          ),
                          if (produit.dateexp != null)
                            Text(
                              'Exp: ${DateFormat('dd/MM/yyyy').format(produit.dateexp!)}',
                              style: const TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _showQuantityDialog(produit),
                          child: Text(
                            produit.quantity > 0 ? 'Ajouter au panier' : 'Commander (rupture)',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(imageUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(Produit produit) {
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool orderByPack = produit.packSize > 1;
    bool usePack = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Commander ${produit.name}'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (orderByPack) ...[
                      Row(
                        children: [
                          const Text('Commander par pack:'),
                          Switch(
                            value: usePack,
                            onChanged: (value) => setState(() => usePack = value),
                          ),
                        ],
                      ),
                      if (usePack)
                        Text(
                          '1 pack = ${produit.packSize} unités (${(produit.price * produit.packSize).toStringAsFixed(2)} DA)',
                        ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: usePack ? 'Nombre de packs' : 'Quantité',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        final quantity = double.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Quantité invalide';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      double quantity = double.parse(quantityController.text);
                      if (usePack) {
                        quantity *= produit.packSize;
                      }
                      ref.read(selectedProduitsProvider.notifier).add(produit, quantity);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${quantity.toStringAsFixed(0)} unités ajoutées'),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentTab.index,
      onTap: (index) => setState(() => _currentTab = ClientTab.values[index]),
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Produits'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Commande'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.diamond), label: 'ParaGalien'),
      ],
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  final Color iconColor;

  CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.iconColor,
  });
}
