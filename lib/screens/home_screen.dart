import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;

import '../main.dart';

class HomeScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // 商品IDと個数を紐づけるマップ
    final quantities = useState<Map<String, int>>({});

    // 個数を取得するメソッド（存在しない場合は0を返す）
    int getQuantity(String productId) {
      return quantities.value[productId] ?? 0;
    }

    // 個数を増やすメソッド
    void incrementQuantity(String productId) {
      quantities.value = {
        ...quantities.value,
        productId: getQuantity(productId) + 1,
      };
    }

    // 個数を減らすメソッド
    void decrementQuantity(String productId) {
      if (getQuantity(productId) > 0) {
        quantities.value = {
          ...quantities.value,
          productId: getQuantity(productId) - 1,
        };
      }
    }

    // カートに入っている商品と数量を元に合計金額を計算するメソッド
    int calculateTotalPrice() {
      int total = 0;
      quantities.value.forEach((productId, quantity) {
        if (quantity > 0) {
          final product = mockProducts.firstWhere((p) => p.id == productId);
          total += product.price * quantity;
        }
      });
      return total;
    }

    // カートに商品があるか確認
    bool hasItemsInCart =
        quantities.value.values.any((quantity) => quantity > 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品リスト'),
      ),
      body: ListView.builder(
        itemCount: mockProducts.length,
        itemBuilder: (BuildContext context, int index) {
          final product = mockProducts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 商品画像
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 商品情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¥${product.price.toString()}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 個数操作ボタン
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: getQuantity(product.id) > 0
                                  ? () => decrementQuantity(product.id)
                                  : null,
                              style: ButtonStyle(
                                backgroundColor: MaterialStatePropertyAll(
                                  getQuantity(product.id) > 0
                                      ? Colors.grey.shade200
                                      : Colors.grey.shade100,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                getQuantity(product.id).toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => incrementQuantity(product.id),
                              style: ButtonStyle(
                                backgroundColor: MaterialStatePropertyAll(
                                  Colors.grey.shade200,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 詳細ボタン
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      // 詳細画面へ遷移する処理を追加予定
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: hasItemsInCart
          ? BottomAppBar(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: () {
                    // 選択された商品と数量を取得
                    final selectedProducts = <String, int>{};
                    quantities.value.forEach((productId, quantity) {
                      if (quantity > 0) {
                        selectedProducts[productId] = quantity;
                      }
                    });

                    // 決済画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          selectedProducts: selectedProducts,
                          totalPrice: calculateTotalPrice(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('購入する (¥${calculateTotalPrice()})'),
                ),
              ),
            )
          : null,
    );
  }
}

// 決済画面
class CheckoutPage extends StatefulWidget {
  final Map<String, int> selectedProducts;
  final int totalPrice;

  const CheckoutPage({
    Key? key,
    required this.selectedProducts,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: XXXAPIKEY を実際のStripe公開可能キーに置き換えてください。
    // 本番環境では、このようなキーをハードコードせず、環境変数など安全な方法で管理してください。
    Stripe.publishableKey = 'XXXAPIKEY';
    Stripe.instance.applySettings();
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Cloud Functionを呼び出してPaymentIntentを作成
      // TODO: YOUR_FIREBASE_PROJECT_ID を実際のプロジェクトIDに、
      // また必要であれば YOUR_FIREBASE_REGION を適切なリージョンに置き換えてください。
      final url = Uri.parse(
          'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/createPaymentIntent');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': widget.totalPrice,
          'currency': 'jpy',
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            'Cloud Function Error: ${errorData['error']?['message'] ?? response.body}');
      }

      final Map<String, dynamic> paymentIntentData = json.decode(response.body);
      final clientSecret = paymentIntentData['clientSecret'];

      if (clientSecret == null) {
        throw Exception('Client secret not found in response.');
      }

      // 2. Stripeで支払いを実行
      // TODO: 本番アプリでは、PaymentMethodParams.cardFromMethodIdやCardFieldを使用して
      // カード情報を安全に収集・処理することを推奨します。
      // BillingDetailsも適切に設定してください。
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(), // 必要に応じて詳細情報を追加
          ),
        ),
      );

      // 3. 成功メッセージを表示してホーム画面に戻る
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('決済が完了しました！'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('決済に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('決済'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 選択された商品一覧
                const Text(
                  '注文内容',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.selectedProducts.entries.map((entry) {
                  final productId = entry.key;
                  final quantity = entry.value;
                  final product =
                      mockProducts.firstWhere((p) => p.id == productId);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text('¥${product.price} × $quantity'),
                    trailing: Text(
                      '¥${product.price * quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),

                const Divider(height: 32),

                // 合計金額
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '合計',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '¥${widget.totalPrice}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 支払い方法選択やお届け先情報など
                const Text(
                  '支払い方法',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // TODO: ここにCardFieldを配置するなどして、実際のカード情報を入力できるようにする
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.credit_card),
                    title: Text('クレジットカード'),
                    // trailing: Icon(Icons.check_circle, color: Colors.green), // Stripe UIが処理
                  ),
                ),
              ],
            ),
          ),

          // 決済ボタン
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('決済する', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
