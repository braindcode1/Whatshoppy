import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({super.key, this.child, this.scrollable=true,  });
  final Widget? child; final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Image.asset('assets/images/background_signin.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          ),
          SafeArea(child: scrollable 
        ?SingleChildScrollView(
          child: child?? const SizedBox(),
          ) : child ?? const SizedBox(),),
        ],
        
          
         
      ),
    );
  }
}
