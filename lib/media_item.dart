import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:Twiv/services/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';
import 'package:Twiv/services/auxilliary.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MediaItem extends StatelessWidget {
  final File file;
  String type;
  ThumbnailRequest thumbnailRequest;
  double size;

  MediaItem({Key key, this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeProvider tp = Provider.of<ThemeProvider>(context);
    double height = 80;
    double width = 95;
    double leftCurve = 8.5;
    if (file.extension == 'mp4' || file.extension == 'mkv') {

      thumbnailRequest = new ThumbnailRequest(
          video: file.path,
          maxWidth: width.toInt(),
          maxHeight: height.toInt(),
          imageFormat: ImageFormat.JPEG,
          quality: 100);
    }
    type = thumbnailRequest!=null?'video':file.extension == 'gif'?'gif':'image';

    Future<ThumbnailResult> genThumbnail(ThumbnailRequest r) async {
      //WidgetsFlutterBinding.ensureInitialized();
      Uint8List bytes;
      final Completer<ThumbnailResult> completer = Completer();
      if (r.thumbnailPath != null) {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
            video: r.video,
            thumbnailPath: r.thumbnailPath,
            imageFormat: r.imageFormat,
            maxWidth: r.maxWidth,
            maxHeight: r.maxHeight,
            quality: r.quality);

        final file = File(thumbnailPath);
        bytes = file.readAsBytesSync();
      } else {
        bytes = await VideoThumbnail.thumbnailData(
            video: r.video,
            imageFormat: r.imageFormat,
            maxWidth: r.maxWidth,
            maxHeight: r.maxHeight,
            quality: r.quality);
      }

      int _imageDataSize = bytes.length;

      final _image = Image.memory(bytes,fit: BoxFit.cover,);
      _image.image
          .resolve(ImageConfiguration())
          .addListener(ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(ThumbnailResult(
          image: _image,
          dataSize: _imageDataSize,
          height: info.image.height,
          width: info.image.width,
        ));
      }));
      return completer.future;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom:15,left: 15,right:15),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(leftCurve)),
          color: tp.aux1,
          boxShadow: [
           tp.myShadow
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: width,
              child: Stack(
                children: <Widget>[
                  SizedBox(
                      height: height,
                      width: width,
                      child: thumbnailRequest == null
                          ? ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(leftCurve)),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                        ),
                      )
                          : FutureBuilder<ThumbnailResult>(
                        future: genThumbnail(thumbnailRequest),
                        builder: (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                                child: Image.asset(
                                  'assets/loading.gif',
                                  height: 30,
                                  width: 30,
                                ));
                          }
                          if (snapshot.hasData) {
                            final _image = snapshot.data.image;

                            return ClipRRect(
                              borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(leftCurve)),
                              child: _image,
                            );
                          }

                          return ClipRRect(
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(leftCurve)),
                            child: Image.asset(
                              'assets/bg2.png',
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      )),
                  type=='video'||type=='gif'? Center(
                    child: SizedBox(
                      height: 30,
                        width: 30,
                      child: Material(
                        borderRadius: BorderRadius.circular(20),
                        color: mytrans,
                        child: Icon(
                          type=='video'?Icons.play_arrow:Icons.gif,
                          color: Colors.white.withOpacity(0.9),
                          size: 14,
                        ),
                      ),
                    )
                  ):Container()
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.varelaRound(
                          color: tp.aux4, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    SizedBox(height: 8,),
                Text(
                  'Modified: ${dateFormatter(file.lastModifiedSync().toString())}',
                  style: GoogleFonts.varelaRound(
                      color: tp.aux42, fontWeight: FontWeight.w400, fontSize: 12),
                ),
                    SizedBox(height: 4,),
                    FutureBuilder<int>(
                      future: file.length(),
                      builder: (context, snapshot) {
                        String size='0';
                        double nsize = 0;
                        if(snapshot.hasData){
                          nsize = snapshot.data /(1024);
                          size = '${nsize.toStringAsFixed(1)}kb';
                          if(nsize>1000){
                            nsize = snapshot.data /(1024*1024);
                            size = '${nsize.toStringAsFixed(1)}mb';
                          }

                        }
                        return Text(
                          'Size: $size',
                          style: GoogleFonts.varelaRound(
                              color: tp.aux42, fontWeight: FontWeight.w400, fontSize: 12),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical:15.0),
              child: VerticalDivider(),
            ),
            IconButton(
              onPressed: (){
                ShareExtend.share(file.path, type);
              },
              icon: Icon(Icons.share,color: tp.aux4,size: 17,),
            ),
            SizedBox(width: 5,)
          ],
        ),
      ),
    );
  }
}

class ThumbnailResult {
  final Image image;
  final int dataSize;
  final int height;
  final int width;

  const ThumbnailResult({this.image, this.dataSize, this.height, this.width});
}

class ThumbnailRequest {
  final String video;
  final String thumbnailPath;
  final ImageFormat imageFormat;
  final int maxHeight;
  final int maxWidth;
  final int timeMs;
  final int quality;

  const ThumbnailRequest(
      {this.video,
      this.thumbnailPath,
      this.imageFormat,
      this.maxHeight,
      this.maxWidth,
      this.timeMs,
      this.quality});
}
