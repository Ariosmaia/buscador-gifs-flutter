import 'dart:convert';

import 'package:buscador_gifs/ui/gif_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:share/share.dart';
// Para imagem transparente
import 'package:transparent_image/transparent_image.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _search;
  int _offset = 0;

  Future<Map> _getGifs() async {
    http.Response response;

    if (_search == null || _search.isEmpty)
      response = await http.get(
          "https://api.giphy.com/v1/gifs/trending?api_key=dqDbVqOnXnXml62u2m49P00DGktAp5Hr&limit=20&rating=G");
    else
      response = await http.get(
          "https://api.giphy.com/v1/gifs/search?api_key=dqDbVqOnXnXml62u2m49P00DGktAp5Hr&q=$_search&limit=19&offset=$_offset&rating=G&lang=pt");

    return json.decode(response.body);
  }

  @override
  void initState() {
    super.initState();

    _getGifs().then((map) {
      print(map);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Imagem e gifs da Internet
        title: Image.network(
            "https://developers.giphy.com/static/img/dev-logo-lg.7404c00322a8.gif"),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                  labelText: "Pesquise Aqui!",
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white))),
              style: TextStyle(color: Colors.white, fontSize: 18.0),
              textAlign: TextAlign.center,
              // Quando clico no confirmar do teclado do celular
              // Pega o texto (text)
              onSubmitted: (text) {
                setState(() {
                  _search = text;
                  // Se eu for pesquisar preciso zerar para os proximos itens
                  _offset = 0;
                });
              },
            ),
          ),
          // Ocupa todo espaço possivel
          Expanded(
            // Espera os dados chegarem
            child: FutureBuilder(
              future: _getGifs(),
              builder: (context, snapshot) {
                // Verifica o estado da conexão
                switch (snapshot.connectionState) {
                  // Carregando nada ou esperando
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return Container(
                      width: 200.0,
                      height: 200.0,
                      alignment: Alignment.center,
                      // Circula que fica rodando na tela de espera
                      child: CircularProgressIndicator(
                        // Cor não vai mudar AlwaysStoppedAnimation
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        // Largura do circulo
                        strokeWidth: 5.0,
                      ),
                    );
                  default:
                    // Erro retonar um container vazio
                    if (snapshot.hasError)
                      return Container();
                    else
                      // Retonar tabela de gifs
                      return _createGifTable(context, snapshot);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  // Verifica se o _search está vazio, caso não ele retorna o tamanho com + 1
  // para carregar mais
  int _getCount(List data) {
    if (_search == null) {
      return data.length;
    } else {
      return data.length + 1;
    }
  }

  Widget _createGifTable(BuildContext context, AsyncSnapshot snapshot) {
    // Mostrar view em formato de grade
    return GridView.builder(
      padding: EdgeInsets.all(10.0),
      // Mostrar como itens são organizados na tela
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // Itens na horizontal
          crossAxisCount: 2, 
          // Espaçemento entre os itens horizontal
          crossAxisSpacing: 10.0, 
          // Espaçamento entre os itens vertical
          mainAxisSpacing: 10.0),
      itemCount: _getCount(snapshot.data["data"]),
      itemBuilder: (context, index) {
        bool naoEstouPesquisandoENaoEhUltimoItem = _search == null || index < snapshot.data["data"].length;
        if (naoEstouPesquisandoENaoEhUltimoItem)
          // Transforma o item para ficar capaz de ser clicado
          return GestureDetector(
            // Faz as imagens aparecer suavemente
            child: FadeInImage.memoryNetwork(
                // Para imagem transparente
                placeholder: kTransparentImage,
                image: snapshot.data["data"][index]["images"]["fixed_height"]["url"],
                height: 300.0,
                fit: BoxFit.cover),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GifPage(snapshot.data["data"][index]),
                ),
              );
            },
            onLongPress: () {
              // Compartilha arquivos
              Share.share(snapshot.data["data"][index]["images"]["fixed_height"]
                  ["url"]);
            },
          );
        else {
          // Irá mostrar o ultimo da lista o carregar mais
          return Container(
            child: GestureDetector(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.add, color: Colors.white, size: 70.0),
                  Text(
                    "Carregar mais...",
                    style: TextStyle(color: Colors.white, fontSize: 22.0),
                  ),
                ],
              ),
              // Carrega os proximos 19 itens
              onTap: () {
                setState(() {
                  _offset += 19;
                });
              },
            ),
          );
        }
      },
    );
  }
}
