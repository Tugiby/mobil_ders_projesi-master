import 'package:flutter/widgets.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

//navigation.dart, uygulamanın navigasyon sistemini bir değişkene bağlar. 
//Böylece bildirim servisi gibi "ekran dışı" yapılar, 
//uygulamanın o an neresinde olursak olalım bizi istediğimiz sayfaya yönlendirebilir. 
//Eğer bu anahtar olmasaydı, 
//bildirimlere tıkladığımızda uygulama sadece ana ekranı açardı, 
//bizi spesifik bir ihbarın detayına götüremezdi.