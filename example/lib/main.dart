import 'dart:developer';

import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:intl/intl.dart';
import 'package:ping_discover_network_plus/ping_discover_network_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discover Printers',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String localIp = '';
  List<String> devices = [];
  bool isDiscovering = false;
  int found = -1;
  TextEditingController portController = TextEditingController(text: '9100');

  void discover(BuildContext ctx) async {
    setState(() {
      isDiscovering = true;
      devices.clear();
      found = -1;
    });

    String ip;
    try {
      ip = '192.168.5.111';
      log('local ip:\t$ip');
    } catch (e) {
      const snackBar = SnackBar(
          content: Text('WiFi is not connected', textAlign: TextAlign.center));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    setState(() {
      localIp = ip;
    });

    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    int port = 9100;
    try {
      port = int.parse(portController.text);
    } catch (e) {
      portController.text = port.toString();
    }
    log('subnet:\t$subnet, port:\t$port');

    final stream = NetworkAnalyzer.i.discover2(subnet, port);

    stream.listen((NetworkAddress addr) {
      if (addr.exists) {
        log('Found device: ${addr.ip}');
        setState(() {
          devices.add(addr.ip);
          found = devices.length;
        });
      }
    })
      ..onDone(() {
        setState(() {
          isDiscovering = false;
          found = devices.length;
        });
      })
      ..onError((dynamic e) {
        const snackBar = SnackBar(
            content: Text('Unexpected exception', textAlign: TextAlign.center));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      });
  }

  Future<void> testReceipt(NetworkPrinter printer) async {
    printer.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    printer.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
        styles: const PosStyles(codeTable: 'CP1252'));
    printer.text('Special 2: blåbærgrød',
        styles: const PosStyles(codeTable: 'CP1252'));

    printer.text('Bold text', styles: const PosStyles(bold: true));
    printer.text('Reverse text', styles: const PosStyles(reverse: true));
    printer.text('Underlined text',
        styles: const PosStyles(underline: true), linesAfter: 1);
    printer.text('Align left', styles: const PosStyles(align: PosAlign.left));
    printer.text('Align center',
        styles: const PosStyles(align: PosAlign.center));
    printer.text('Align right',
        styles: const PosStyles(align: PosAlign.right), linesAfter: 1);

    printer.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    printer.text('Text size 200%',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    // Print image
    final ByteData data = await rootBundle.load('assets/logo.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final Image? image = decodeImage(bytes);
    if (image != null) {
      printer.imageRaster(image, imageFn: PosImageFn.graphics);
    }
    // Print image using alternative commands
    // printer.imageRaster(image);
    // printer.imageRaster(image, imageFn: PosImageFn.graphics);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    printer.barcode(Barcode.upcA(barData));

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    // printer.text(
    //   'hello ! 中文字 # world @ éphémère &',
    //   styles: PosStyles(codeTable: PosCodeTable.westEur),
    //   containsChinese: true,
    // );

    printer.feed(2);
    printer.cut();
  }

  Future<void> printDemoReceipt(NetworkPrinter printer) async {
    // Print image
    final ByteData data = await rootBundle.load('assets/rabbit_black.jpg');
    final Uint8List bytes = data.buffer.asUint8List();
    final Image? image = decodeImage(bytes);
    if (image != null) {
      // printer.image(image);
    }

    printer.text('GROCERYLY',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    printer.text('889  Watson Lane',
        styles: const PosStyles(align: PosAlign.center));
    printer.text('New Braunfels, TX',
        styles: const PosStyles(align: PosAlign.center));
    printer.text('Tel: 830-221-1234',
        styles: const PosStyles(align: PosAlign.center));
    printer.text('Web: www.example.com',
        styles: const PosStyles(align: PosAlign.center), linesAfter: 1);

    printer.hr();
    printer.row([
      PosColumn(text: 'Qty', width: 1),
      PosColumn(text: 'Item', width: 7),
      PosColumn(
          text: 'Price',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: 'Total',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    printer.row([
      PosColumn(text: '2', width: 1),
      PosColumn(text: 'ONION RINGS', width: 7),
      PosColumn(
          text: '0.99',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '1.98',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.row([
      PosColumn(text: '1', width: 1),
      PosColumn(text: 'PIZZA', width: 7),
      PosColumn(
          text: '3.45',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '3.45',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.row([
      PosColumn(text: '1', width: 1),
      PosColumn(text: 'SPRING ROLLS', width: 7),
      PosColumn(
          text: '2.99',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '2.99',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.row([
      PosColumn(text: '3', width: 1),
      PosColumn(text: 'CRUNCHY STICKS', width: 7),
      PosColumn(
          text: '0.85',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '2.55',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.hr();

    printer.row([
      PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
      PosColumn(
          text: '\$10.97',
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
    ]);

    printer.hr(ch: '=', linesAfter: 1);

    printer.row([
      PosColumn(
          text: 'Cash',
          width: 8,
          styles:
              const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
      PosColumn(
          text: '\$15.00',
          width: 4,
          styles:
              const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
    ]);
    printer.row([
      PosColumn(
          text: 'Change',
          width: 8,
          styles:
              const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
      PosColumn(
          text: '\$4.03',
          width: 4,
          styles:
              const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
    ]);

    printer.feed(2);
    printer.text('Thank you!',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    final now = DateTime.now();
    final formatter = DateFormat('MM/dd/yyyy H:m');
    final String timestamp = formatter.format(now);
    printer.text(timestamp,
        styles: const PosStyles(align: PosAlign.center), linesAfter: 2);

    // Print QR Code from image
    // try {
    //   const String qrData = 'example.com';
    //   const double qrSize = 200;
    //   final uiImg = await QrPainter(
    //     data: qrData,
    //     version: QrVersions.auto,
    //     gapless: false,
    //   ).toImageData(qrSize);
    //   final dir = await getTemporaryDirectory();
    //   final pathName = '${dir.path}/qr_tmp.png';
    //   final qrFile = File(pathName);
    //   final imgFile = await qrFile.writeAsBytes(uiImg.buffer.asUint8List());
    //   final img = decodeImage(imgFile.readAsBytesSync());

    //   printer.image(img);
    // } catch (e) {
    //   log(e);
    // }

    // Print QR Code using native function
    // printer.qrcode('example.com');

    printer.feed(1);
    printer.cut();
  }

  void testlog(String printerIp, BuildContext ctx) async {
    final scfMessage = ScaffoldMessenger.of(context);
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(printerIp, port: 9100);

    if (res == PosPrintResult.success) {
      // DEMO RECEIPT
      await printDemoReceipt(printer);
      // TEST PRINT
      // await testReceipt(printer);
      printer.disconnect();
    }

    final snackBar =
        SnackBar(content: Text(res.msg, textAlign: TextAlign.center));
    scfMessage.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Printers'),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: 'Port',
                  ),
                ),
                const SizedBox(height: 10),
                Text('Local ip: $localIp',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 15),
                ElevatedButton(
                    onPressed: isDiscovering ? null : () => discover(context),
                    child: Text(isDiscovering ? 'Discovering...' : 'Discover')),
                const SizedBox(height: 15),
                found >= 0
                    ? Text('Found: $found device(s)',
                        style: const TextStyle(fontSize: 16))
                    : Container(),
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () => testlog(devices[index], context),
                        child: Column(
                          children: <Widget>[
                            Container(
                              height: 60,
                              padding: const EdgeInsets.only(left: 10),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.print),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          '${devices[index]}:${portController.text}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          'Click to print a test receipt',
                                          style: TextStyle(
                                              color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
