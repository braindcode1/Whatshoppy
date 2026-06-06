import 'package:flutter/material.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State <ProductsScreen> createState()=>_ProductsScreenState();}
  class _ProductsScreenState extends State <ProductsScreen>{
    final List <Map<String,dynamic>> Products=[
      {
        "name": "formation CEO",
        "sku":"PROD-001",
        "category":"formation",
        "price":"29.00€",
        "stock":48,
        "color":Colors.green,
      },
    ];
    int currentIndex=0;
    @override
    Widget build(BuildContext context){
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Products",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: const [
            Icon(Icons.search, color: Colors.black),
            SizedBox(width: 15),
            Icon(Icons.notifications_none,color: Colors.black),
            SizedBox(width: 15),
            Icon(Icons.settings_outlined,color: Colors.black),
            SizedBox(width: 15),
          ],
        ),
        body: Padding(padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Inventory",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(onPressed: (){
                  Navigator.push(context, 
                  MaterialPageRoute(builder: (_)=> const AddProductScreen(),
                  ),
                  );
                }, 
                icon: const Icon(
                  Icons.add,
                  color: Colors.green,
                ),
                label: const Text("Add Product",
                style: TextStyle(
                  color: Colors.green,
                ),),),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(child: ListView.builder(
              itemCount: Products.length,
              itemBuilder: (context,index){
                final item= Products[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: item["color"].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.image,
                          color: item["Color"],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["name"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${item["sku"]} - ${item["category"]}",
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                          
                        Row(
                                children: [
                                  Text(
                                    item["price"],
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 10),

                                  stockStatus(
                                      item["stock"]),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Column(
                          children: [
                            Text(
                              "${item["stock"]}",
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),

                            const Text(
                              "units",
                              style: TextStyle(
                                color:
                                    Colors.black45,
                              ),
                            ),

                            const SizedBox(height: 8),

                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailsScreen(
                                      productName:
                                          item["name"],
                                    ),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.add_circle_outline,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Clients",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: "Products",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: "Inbox",
          ),
        ],
      ),
    );
  }

  Widget stockStatus(int stock) {
    if (stock == 0) {
      return badge("Out of stock", Colors.red);
    } else if (stock <= 10) {
      return badge("Low stock", Colors.orange);
    } else {
      return badge("In stock", Colors.green);
    }
  }

  Widget badge(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10,
              vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
      ),
      body: const Center(
        child: Text(
          "Create new product here",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  final String productName;

  const ProductDetailsScreen({
    super.key,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
      ),
      body: Center(
        child: Text(
          productName,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}