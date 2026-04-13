import 'package:flutter/material.dart';
import 'package:focusmaxxer/screens/loginpage.dart';

class OnboardingPage extends StatefulWidget {
  //perché in questo modo la pagina ricorda in quale schermata del carosello siamo
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller =
      PageController(); //per far andare il carosello alla pagina successiva
  int _currentPage =
      0; //variabile che assume valore 0,1,2 per far accendere la barra in basso a sx

  // Dati delle schermate
  final List<Map<String, String>> _pages = [
    //map è una lista di mappe, per non fare 3 pagine diverse. Salviamo solo i dati che cambiamo (titolo, descrizione, icona)
    {
      'title': 'IL TUO BIO-COACH',
      'desc':
          'Studia in modo sostenibile (Target 4.7) ed evita il burnout con il monitoraggio.',
      'icon': 'psychology',
    },
    {
      'title': 'ASCOLTA IL CORPO',
      'desc':
          'Utilizzia i dati del tuo dispositivo wearable per capire in tempo reale quando le tue risorse mentali calano.',
      'icon': 'favorite',
    },
    {
      'title': 'FOCUS PROFONDO',
      'desc':
          'Affidati ai nostri trigger per pause attive e sessioni di studio ad alta efficienza.',
      'icon': 'bolt',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //struttura di base
      body: Stack(
        //permette di sovrapporre i widget (carosello e bottoni). Carosello come "sfondo", bottoni incollati "sopra"
        children: [
          // 1. CAROSELLO (PageView)
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(
              () => _currentPage = index,
            ), //quando faccio swipe oppure premo avanti, aggiorno currentPage e quindi l'indice in basso a sx
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(
                title: _pages[index]['title']!,
                desc: _pages[index]['desc']!,
                icon: _pages[index]['icon']!,
              );
            },
          ),

          // 2. INDICATORE A PUNTI E BOTTONE (In basso)
          Positioned(
            //posiziono i puntini a sinistra e il bottone a destra
            bottom: 50,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Puntini (Indicatori)
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.cyanAccent
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Pulsante Avanti / Inizia
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      //se siamo sull'ultima pagina
                      // Vai al Login
                      Navigator.pushReplacement(
                        //vado alla pagina log in e non torno più indietro
                        // così non possiamo tornare indietro quando siamo nella pagina di log in
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    } else {
                      //altrimenti (se non sono nell'ultima pagina)
                      // Vai alla pagina successiva
                      _controller.nextPage(
                        //passo alla prossima pagina
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'INIZIA' : 'AVANTI',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget riutilizzabile per ogni singola pagina del carosello
  Widget _buildPage({
    required String title,
    required String desc,
    required String icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon == 'psychology'
                ? Icons.psychology
                : icon == 'favorite'
                ? Icons.favorite
                : Icons.bolt,
            size: 100,
            color: Colors.cyanAccent,
          ),
          const SizedBox(
            height: 48,
          ), //creo spazio vuoto per distanziare i vari elementi
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
