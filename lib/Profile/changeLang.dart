import 'package:flutter/material.dart';
import 'package:pakfoundf/l10n/localeProvider.dart';
import 'package:provider/provider.dart';
//import 'locale_provider.dart';

class ChangeLanguageScreen extends StatefulWidget {
  const ChangeLanguageScreen({Key? key}) : super(key: key);

  @override
  _ChangeLanguageScreenState createState() => _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
  @override
  Widget build(BuildContext context) {
    Locale locale = context.watch<LocaleProvider>().locale;
    bool _isEnglishSelected = locale.languageCode == 'en';

    void _setLanguage(bool isEnglish) {
      Locale newLocale = isEnglish ? const Locale('en') : const Locale('ur');
      context.read<LocaleProvider>().setLocale(newLocale);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Select Language',style: TextStyle(color: Colors.white),),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text('Please choose the preferred language'),
          SizedBox(height: 5,),
          InkWell(
            onTap: () => _setLanguage(true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _isEnglishSelected ? Colors.blue : Colors.grey[200],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'English',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isEnglishSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Container(
                    width: 50,
                    child: const Image(image: AssetImage('assets/englandflag.png'),)),
                  Icon(
                    Icons.check_circle,
                    color: _isEnglishSelected ? Colors.white : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _setLanguage(false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _isEnglishSelected ? Colors.grey[200] : Colors.blue,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  Text(
                    '      اردو',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isEnglishSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  Container(width:50,
                   child:  const Image(image: AssetImage('assets/pakflag.png'))),
                  Icon(
                    Icons.check_circle,
                    color: _isEnglishSelected ? Colors.transparent : Colors.white,
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
