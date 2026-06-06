' Conception - WhatShoppy

' Fichier PlantUML contenant plusieurs diagrammes.

' Chaque diagramme est delimite par @startuml et @enduml.



@startuml
title WhatShoppy - demarrage, connexion et session locale

actor "Admin" as Admin
participant "Flutter App\nlib/main.dart" as Main
participant "WelcomeScreen\nlib/screens/welcome_screen.dart" as Welcome
participant "SignInScreen\nlib/screens/signin_screen.dart" as SignIn
participant "AuthService\nlib/services/auth_service.dart" as AuthService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Express App\nbackend/server.js" as Server
participant "Auth route\nbackend/routes/auth.js" as AuthRoute
database "Supabase Auth + public.profiles" as DB
collections "SharedPreferences\nLocalStorageService" as LocalStore
participant "DashboardScreens\nlib/screens/dashboard_screens.dart" as Dashboard

Admin -> Main: ouvrir l'application
Main -> Welcome: home = WelcomeScreen()
Admin -> Welcome: appuyer sur Sign In
Welcome -> SignIn: Navigator.push(SignInScreen)
Admin -> SignIn: saisir email + password
SignIn -> AuthService: signIn(email, password)
AuthService -> Api: POST /api/auth/login

Api -> Server: GET /health si baseUrl non resolu
Server --> Api: {success: true}
Api -> Server: POST /api/auth/login
Server -> AuthRoute: router /api/auth/login
AuthRoute -> DB: signInWithPassword(email, password)
DB --> AuthRoute: user + session
AuthRoute -> DB: SELECT * FROM profiles WHERE id = user.id
DB --> AuthRoute: profile(admin)
AuthRoute --> Server: JSON success + user + profile
Server --> Api: reponse HTTP 200
Api --> AuthService: Map success
AuthService -> LocalStore: saveUser(userId, email, role)
AuthService --> SignIn: user
SignIn -> Dashboard: Navigator.pushAndRemoveUntil()

@enduml

@startuml
title WhatShoppy - chargement dashboard

actor "Admin" as Admin
participant "DashboardScreens\nlib/screens/dashboard_screens.dart" as Dashboard
participant "DashboardService\nlib/services/dashboard_service.dart" as DashService
collections "SharedPreferences\nLocalStorageService" as LocalStore
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Express App\nbackend/server.js" as Server
participant "Dashboard route\nbackend/routes/dashboard.js" as DashRoute
database "Supabase DB\nproducts, clients, orders" as DB

Admin -> Dashboard: ouvrir Dashboard
Dashboard -> DashService: loadDashboard()
DashService -> LocalStore: getCurrentUserId()
LocalStore --> DashService: user_id
DashService -> Api: GET /api/dashboard?user_id
Api -> Server: HTTP GET /api/dashboard
Server -> DashRoute: router /api/dashboard

par Requetes statistiques
  DashRoute -> DB: SELECT id FROM products WHERE user_id
  DashRoute -> DB: SELECT id FROM clients WHERE user_id
  DashRoute -> DB: SELECT id,total,status FROM orders WHERE user_id
end

DB --> DashRoute: listes produits, clients, commandes
DashRoute -> DashRoute: calcul products_count, clients_count,\norders_count, pending_orders, total_revenue
DashRoute --> Server: JSON success + stats
Server --> Api: HTTP 200
Api --> DashService: data
DashService --> Dashboard: DashboardFetchResult
Dashboard --> Admin: afficher revenus, commandes, clients, produits

@enduml

@startuml
title WhatShoppy - cycle de vie produit

actor "Admin" as Admin
participant "StockScreen\nlib/screens/stock_screen.dart" as Stock
participant "AddProductScreen\nlib/screens/add_product_screen.dart" as AddProduct
participant "ProductDetailsScreen\nlib/screens/product_details_screen.dart" as Details
participant "CategoryService\nlib/services/category_service.dart" as CatService
participant "AiService\nlib/services/ai_service.dart" as AiService
participant "ProductService\nlib/services/product_service.dart" as ProductService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Products route\nbackend/routes/products.js" as ProductRoute
participant "Categories route\nbackend/routes/categories.js" as CatRoute
participant "AI route\nbackend/routes/ai.js" as AiRoute
participant "FastAPI ML\nbackend/ai_model/app.py" as FastApi
database "Supabase DB\nproducts, categories" as DB

Admin -> Stock: ouvrir Stock
Stock -> ProductService: getProducts()
ProductService -> Api: GET /api/products?user_id
Api -> ProductRoute: HTTP GET /api/products
ProductRoute -> DB: SELECT * FROM products WHERE user_id ORDER BY created_at
DB --> ProductRoute: produits
ProductRoute --> Api: JSON success + produits
Api --> ProductService: data
ProductService --> Stock: liste produits

Admin -> Stock: appuyer Add Product
Stock -> AddProduct: Navigator.push()
AddProduct -> CatService: fetchCategories()
CatService -> Api: GET /api/categories?user_id
Api -> CatRoute: HTTP GET /api/categories
CatRoute -> DB: SELECT * FROM categories WHERE user_id ORDER BY nom
DB --> CatRoute: categories
CatRoute --> Api: JSON success + categories
Api --> CatService: data
CatService --> AddProduct: categories

opt nouvelle categorie
  Admin -> AddProduct: saisir categorie
  AddProduct -> CatService: addCategory(nom)
  CatService -> Api: POST /api/categories
  Api -> CatRoute: HTTP POST /api/categories
  CatRoute -> DB: SELECT categories WHERE user_id AND nom ILIKE
  alt categorie existe
    DB --> CatRoute: categorie existante
    CatRoute --> Api: success + categorie existante
  else categorie absente
    CatRoute -> DB: INSERT INTO categories(nom, user_id)
    DB --> CatRoute: categorie creee
    CatRoute --> Api: success + categorie creee
  end
  Api --> CatService: data
  CatService --> AddProduct: nom categorie
end

opt analyse IA d'image
  Admin -> AddProduct: choisir image + lancer analyse
  AddProduct -> AiService: analyzeProductImage(file)
  AiService -> Api: POST /api/ai/analyze-image
  Api -> AiRoute: image_base64 + mime_type
  AiRoute -> FastApi: POST /analyze-image
  FastApi -> FastApi: decoder image, extraire HOG/RGB,\nscaler.pkl + clothes_svm_model.pkl
  FastApi --> AiRoute: category, confidence, tags, price
  AiRoute --> Api: JSON success source=local
  Api --> AiService: data
  AiService --> AddProduct: pre-remplir nom, description,\ncategorie, prix estime
end

Admin -> AddProduct: sauvegarder produit
AddProduct -> ProductService: createProduct(productData)
ProductService -> Api: POST /api/products
Api -> ProductRoute: HTTP POST /api/products
ProductRoute -> DB: INSERT INTO products(...)
DB --> ProductRoute: produit cree
ProductRoute --> Api: HTTP 201 + produit
Api --> ProductService: data
ProductService --> AddProduct: produit cree
AddProduct --> Stock: Navigator.pop(saved)

Admin -> Stock: ouvrir produit
Stock -> Details: Navigator.push(product)
Admin -> Details: modifier produit
Details -> ProductService: updateProduct(id, data)
ProductService -> Api: PUT /api/products/:id
Api -> ProductRoute: HTTP PUT /api/products/:id
ProductRoute -> DB: UPDATE products WHERE id AND user_id
DB --> ProductRoute: produit modifie
ProductRoute --> Api: success + produit
Api --> ProductService: data
ProductService --> Details: produit modifie

opt suppression produit
  Admin -> Details: confirmer suppression
  Details -> ProductService: deleteProduct(id)
  ProductService -> Api: DELETE /api/products/:id
  Api -> ProductRoute: HTTP DELETE /api/products/:id
  ProductRoute -> DB: DELETE FROM products WHERE id AND user_id
  DB --> ProductRoute: suppression OK
  ProductRoute --> Api: success
  Api --> ProductService: OK
  Details --> Stock: produit supprime
end

@enduml

@startuml
title WhatShoppy - cycle de vie commande existante

actor "Admin" as Admin
participant "OrdersListScreen\nlib/screens/order_list_screen.dart" as OrderList
participant "OrdersScreen\nlib/screens/orders_screen.dart" as OrderDetails
participant "RevenueAnalyticsScreen\nlib/screens/revenue_analytics_screen.dart" as Revenue
participant "OrderService\nlib/services/order_service.dart" as OrderService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Orders route\nbackend/routes/orders.js" as OrderRoute
database "Supabase DB\norders, order_line_items, clients" as DB

Admin -> OrderList: ouvrir Orders
OrderList -> OrderService: getOrders()
OrderService -> Api: GET /api/orders?user_id
Api -> OrderRoute: HTTP GET /api/orders
OrderRoute -> DB: SELECT orders + client:client_id\nWHERE orders.user_id
DB --> OrderRoute: commandes + client
OrderRoute --> Api: JSON success + commandes
Api --> OrderService: data
OrderService --> OrderList: liste commandes

Admin -> OrderList: ouvrir une commande
OrderList -> OrderDetails: Navigator.push(order)
OrderDetails -> OrderService: getOrderLineItems(orderId)
OrderService -> Api: GET /api/orders/:id/items?user_id
Api -> OrderRoute: HTTP GET /api/orders/:id/items
OrderRoute -> DB: SELECT id FROM orders WHERE id
DB --> OrderRoute: commande trouvee
OrderRoute -> DB: SELECT * FROM order_line_items WHERE order_id
DB --> OrderRoute: lignes commande
OrderRoute --> Api: JSON success + lignes
Api --> OrderService: data
OrderService --> OrderDetails: items

Admin -> OrderDetails: changer statut
OrderDetails -> OrderService: updateOrderStatus(id, status)
OrderService -> Api: PUT /api/orders/:id/status
Api -> OrderRoute: HTTP PUT /api/orders/:id/status
OrderRoute -> OrderRoute: verifier status dans\nPending/Processing/Shipped/Delivered/Cancelled
OrderRoute -> DB: UPDATE orders SET status\nWHERE id AND user_id
DB --> OrderRoute: commande modifiee
OrderRoute --> Api: JSON success + commande
Api --> OrderService: data
OrderService --> OrderDetails: statut mis a jour

opt analyse revenus
  Admin -> Revenue: ouvrir RevenueAnalyticsScreen
  Revenue -> OrderService: getOrders()
  OrderService -> Api: GET /api/orders?user_id
  Api -> OrderRoute: HTTP GET /api/orders
  OrderRoute -> DB: SELECT orders + client
  DB --> OrderRoute: commandes
  OrderRoute --> Api: data
  Api --> OrderService: data
  OrderService --> Revenue: calcul UI des revenus
end

@enduml

@startuml
title WhatShoppy - consultation clients

actor "Admin" as Admin
participant "ClientsScreen\nlib/screens/clients_screen.dart" as ClientsScreen
participant "ClientProfileScreen\nlib/screens/client_profile.dart" as ClientProfile
participant "ClientService\nlib/services/client_service.dart" as ClientService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Clients route\nbackend/routes/clients.js" as ClientRoute
database "Supabase DB\nclients" as DB

Admin -> ClientsScreen: ouvrir Clients
ClientsScreen -> ClientService: getClients()
ClientService -> Api: GET /api/clients?user_id
Api -> ClientRoute: HTTP GET /api/clients
ClientRoute -> DB: SELECT * FROM clients WHERE user_id ORDER BY created_at
DB --> ClientRoute: clients
ClientRoute --> Api: JSON success + clients
Api --> ClientService: data
ClientService --> ClientsScreen: liste clients

Admin -> ClientsScreen: rechercher ou selectionner client
ClientsScreen -> ClientProfile: Navigator.push(client)
ClientProfile --> Admin: afficher profil depuis les donnees deja chargees

@enduml

@startuml
title WhatShoppy - cycle de vie messagerie

actor "Admin" as Admin
participant "InboxListScreen\nlib/screens/inbox_list_screen.dart" as Inbox
participant "ChatScreen\nlib/screens/chat_screen.dart" as Chat
participant "MessageService\nlib/services/message_service.dart" as MessageService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Messages route\nbackend/routes/messages.js" as MessageRoute
database "Supabase DB\nconversations, messages, clients" as DB

Admin -> Inbox: ouvrir inbox
Inbox -> MessageService: getInboxItems()
MessageService -> Api: GET /api/messages?user_id
Api -> MessageRoute: HTTP GET /api/messages
MessageRoute -> DB: SELECT conversations + client:client_id\nWHERE user_id ORDER BY updated_at
DB --> MessageRoute: conversations
MessageRoute --> Api: JSON success + conversations
Api --> MessageService: data
MessageService --> Inbox: conversations

Admin -> Inbox: ouvrir une conversation
Inbox -> Chat: Navigator.push(conversation)
Chat -> MessageService: markAsRead(conversationId)
MessageService -> Api: PUT /api/messages/:id/read
Api -> MessageRoute: HTTP PUT /api/messages/:id/read
MessageRoute -> DB: UPDATE conversations SET unread_count=0\nWHERE id AND user_id
DB --> MessageRoute: OK
MessageRoute --> Api: success

Chat -> MessageService: getMessages(conversationId)
MessageService -> Api: GET /api/messages/:id?user_id
Api -> MessageRoute: HTTP GET /api/messages/:id
MessageRoute -> DB: SELECT id FROM conversations\nWHERE id AND user_id
DB --> MessageRoute: conversation valide
MessageRoute -> DB: SELECT * FROM messages\nWHERE conversation_id ORDER BY created_at
DB --> MessageRoute: messages
MessageRoute -> DB: UPDATE conversations SET unread_count=0 WHERE id
MessageRoute --> Api: JSON success + messages
Api --> MessageService: data
MessageService --> Chat: messages

Admin -> Chat: envoyer message
Chat -> MessageService: sendMessage(conversationId, text)
MessageService -> Api: POST /api/messages/:id
Api -> MessageRoute: HTTP POST /api/messages/:id
MessageRoute -> DB: SELECT id FROM conversations\nWHERE id AND user_id
DB --> MessageRoute: conversation valide
MessageRoute -> DB: INSERT INTO messages(conversation_id,\nsender_type='business', text)
DB --> MessageRoute: message cree
MessageRoute -> DB: UPDATE conversations SET last_message=text
DB --> MessageRoute: conversation mise a jour
MessageRoute --> Api: HTTP 201 + message
Api --> MessageService: data
MessageService --> Chat: message envoye

@enduml

@startuml
title WhatShoppy - parametres compte et business

actor "Admin" as Admin
participant "SettingsScreen\nlib/screens/settings_screen.dart" as Settings
participant "SettingsService\nlib/services/settings_service.dart" as SettingsService
participant "AuthService\nlib/services/auth_service.dart" as AuthService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Settings route\nbackend/routes/settings.js" as SettingsRoute
participant "Auth route\nbackend/routes/auth.js" as AuthRoute
database "Supabase DB\nauth.users, profiles, business_settings" as DB
collections "SharedPreferences\nLocalStorageService" as LocalStore

Admin -> Settings: ouvrir Settings
Settings -> LocalStore: getEmail()
LocalStore --> Settings: email local
Settings -> SettingsService: getBusinessSettings()
SettingsService -> LocalStore: getCurrentUserId()
LocalStore --> SettingsService: user_id
SettingsService -> Api: GET /api/settings/business?user_id
Api -> SettingsRoute: HTTP GET /api/settings/business
SettingsRoute -> DB: SELECT * FROM business_settings WHERE user_id
DB --> SettingsRoute: settings ou valeurs vides
SettingsRoute --> Api: JSON success
Api --> SettingsService: data
SettingsService --> Settings: business_name, whatsapp_number

alt modifier business
  Admin -> Settings: modifier business_name/whatsapp_number
  Settings -> SettingsService: upsertBusinessSettings()
  SettingsService -> Api: PUT /api/settings/business
  Api -> SettingsRoute: HTTP PUT /api/settings/business
  SettingsRoute -> DB: UPSERT business_settings ON CONFLICT user_id
  DB --> SettingsRoute: ligne creee ou mise a jour
  SettingsRoute --> Api: success + settings
  Api --> SettingsService: data
  SettingsService --> Settings: settings sauvegardes
else modifier email
  Admin -> Settings: saisir nouvel email
  Settings -> AuthService: updateAccountEmail(newEmail)
  AuthService -> LocalStore: getCurrentUserId()
  LocalStore --> AuthService: user_id
  AuthService -> Api: PUT /api/auth/update-email
  Api -> AuthRoute: HTTP PUT /api/auth/update-email
  AuthRoute -> DB: admin.updateUserById(user_id, email)
  AuthRoute -> DB: UPDATE profiles SET email WHERE id=user_id
  DB --> AuthRoute: OK
  AuthRoute --> Api: success
  Api --> AuthService: OK
  AuthService -> LocalStore: saveUser(userId, newEmail, role)
else modifier mot de passe
  Admin -> Settings: saisir current_password + new_password
  Settings -> AuthService: updateAccountPassword()
  AuthService -> Api: PUT /api/auth/update-password
  Api -> AuthRoute: HTTP PUT /api/auth/update-password
  AuthRoute -> DB: admin.getUserById(user_id)
  AuthRoute -> DB: signInWithPassword(email, current_password)
  AuthRoute -> DB: admin.updateUserById(user_id, password)
  DB --> AuthRoute: OK
  AuthRoute --> Api: success
end

opt deconnexion
  Admin -> Settings: Sign out
  Settings -> AuthService: signOut()
  AuthService -> LocalStore: clear()
  Settings --> Admin: retour SignInScreen
end

@enduml

@startuml
title WhatShoppy - cycle mot de passe oublie

actor "Admin" as Admin
participant "ForgotPasswordScreen\nlib/screens/forget_password.dart" as Forgot
participant "AuthService\nlib/services/auth_service.dart" as AuthService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Auth route\nbackend/routes/auth.js" as AuthRoute
database "Supabase Auth\nauth.users" as AuthDB

Admin -> Forgot: saisir email
Forgot -> AuthService: resetPasswordForEmail(email)
AuthService -> Api: POST /api/auth/forgot-password
Api -> AuthRoute: HTTP POST /api/auth/forgot-password
AuthRoute -> AuthDB: resetPasswordForEmail(email, redirectTo)
AuthDB --> AuthRoute: email de recovery envoye si compte existe
AuthRoute --> Api: success
Api --> AuthService: OK
AuthService --> Forgot: afficher message

Admin -> Forgot: ouvrir lien recovery avec tokens
Forgot -> AuthService: resetPasswordWithToken(access, refresh, newPassword)
AuthService -> Api: POST /api/auth/reset-password
Api -> AuthRoute: HTTP POST /api/auth/reset-password
AuthRoute -> AuthDB: setSession(access_token, refresh_token)
AuthRoute -> AuthDB: updateUser(password)
AuthDB --> AuthRoute: mot de passe mis a jour
AuthRoute --> Api: success
Api --> AuthService: OK
AuthService --> Forgot: retour connexion

@enduml

@startuml
title WhatShoppy - prediction prix locale

actor "Admin" as Admin
participant "PricePredictionScreen\nlib/screens/price_prediction_screen.dart" as PriceScreen
participant "PricePredictionService\nlib/services/price_prediction_service.dart" as PriceService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "AI route\nbackend/routes/ai.js" as AiRoute
participant "FastAPI ML\nbackend/ai_model/app.py" as FastApi
collections "Modele prix\nfashion_price_predictor.pkl" as PriceModel

Admin -> PriceScreen: saisir attributs produit
PriceScreen -> PriceService: predictBestPrice(input)
PriceService -> Api: POST /api/ai/predict-price
Api -> AiRoute: HTTP POST /api/ai/predict-price
AiRoute -> AiRoute: valider Brand, Category, Color,\nSize, Material, Gender, Season, Brand_Tier
AiRoute -> FastApi: POST /predict-price
FastApi -> PriceModel: charger modele si necessaire
FastApi -> FastApi: construire DataFrame + model.predict()
FastApi --> AiRoute: recommended_price
AiRoute --> Api: JSON success + recommended_price
Api --> PriceService: data
PriceService --> PriceScreen: prix recommande
PriceScreen --> Admin: afficher prediction

@enduml

@startuml
title WhatShoppy - chatbot d'aide

actor "Admin" as Admin
participant "ChatbotScreen\nlib/screens/chatbot_screen.dart" as ChatbotScreen
participant "ChatbotService\nlib/services/chatbot_service.dart" as ChatbotService
participant "ApiClient\nlib/services/api_client.dart" as Api
participant "Chatbot route\nbackend/routes/chatbot.js" as ChatbotRoute
participant "Gemini API\nsi GEMINI_API_KEY existe" as Gemini

Admin -> ChatbotScreen: envoyer question
ChatbotScreen -> ChatbotService: sendMessage(message, history)
ChatbotService -> Api: POST /api/chatbot
Api -> ChatbotRoute: HTTP POST /api/chatbot

alt GEMINI_API_KEY configure
  ChatbotRoute -> Gemini: generateContent(system_prompt, history, message)
  alt Gemini repond
    Gemini --> ChatbotRoute: texte assistant
    ChatbotRoute --> Api: success fallback=false reply
  else erreur Gemini
    ChatbotRoute -> ChatbotRoute: getLocalReply(message)
    ChatbotRoute --> Api: success fallback=true reply local
  end
else GEMINI_API_KEY absent
  ChatbotRoute -> ChatbotRoute: getLocalReply(message)
  ChatbotRoute --> Api: success fallback=true reply local
end

Api --> ChatbotService: reply
ChatbotService --> ChatbotScreen: texte reponse
ChatbotScreen --> Admin: afficher reponse

@enduml

@startuml
title Cycle de vie Produit WhatShoppy

[*] --> FormulaireProduit : AddProductScreen
FormulaireProduit --> AnalyseIA : option image\nAiService.analyzeProductImage()
AnalyseIA --> FormulaireProduit : champs pre-remplis
FormulaireProduit --> ProduitCree : ProductService.createProduct()\nPOST /api/products
ProduitCree --> StockAffiche : StockScreen reload\nGET /api/products
StockAffiche --> ProduitModifie : ProductDetailsScreen\nPUT /api/products/:id
ProduitModifie --> StockAffiche : reponse success
StockAffiche --> ProduitSupprime : DELETE /api/products/:id
ProduitSupprime --> [*]

@enduml

@startuml
title Cycle de vie statut Commande

[*] --> Pending
Pending --> Processing : PUT /api/orders/:id/status
Processing --> Shipped : PUT /api/orders/:id/status
Shipped --> Delivered : PUT /api/orders/:id/status

Pending --> Cancelled : annulation
Processing --> Cancelled : annulation
Shipped --> Cancelled : annulation si autorisee par UI

Delivered --> [*]
Cancelled --> [*]

note right of Pending
Statuts valides selon backend/routes/orders.js
et contrainte orders_status_check.
end note

@enduml

@startuml
title Cycle de vie Conversation Client

[*] --> ConversationExistante : ligne dans conversations
ConversationExistante --> InboxChargee : GET /api/messages
InboxChargee --> ConversationOuverte : GET /api/messages/:id
ConversationOuverte --> Lue : PUT /api/messages/:id/read\nunread_count = 0
Lue --> MessageEnvoye : POST /api/messages/:id\nINSERT messages
MessageEnvoye --> ConversationMiseAJour : UPDATE conversations.last_message
ConversationMiseAJour --> ConversationOuverte

@enduml
