
import 'dart:io';
import 'dart:math';

import 'package:Twiv/models/video_variant.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:twitter_api/twitter_api.dart';

import 'ApiResponse.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
//  https://twitter.com/Kbarbiie2/status/1292529908757999616?s=20

  static String consumerApiKey = "QHtSqvtg3ZqRJ0DNDU2ps9S1X";
  static String consumerApiSecret = "C3DTBh71fvIdfuWVtoEpcIcTuLTB0fzD4xd3nJ9fH8QtxxXnQr";
  static String accessToken = "1085589956817575937-AfD05rDbrEZUn4U3Qx0PWzmXJjMoj6";
  static String accessTokenSecret = "D7EQtXQ0wM2Af1rkSFRRAysaxon4bB6Wv2hnrso2F62ye";

  // Creating the twitterApi Object with the secret and public keys
  // These keys are generated from the twitter developer page
  // Dont share the keys with anyone
  static final _twitterOauth = new twitterApi(
      consumerKey: consumerApiKey,
      consumerSecret: consumerApiSecret,
      token: accessToken,
      tokenSecret: accessTokenSecret
  );

  // Make the request to twitter
   static Future<void> twitterRequest(String url){
     _twitterOauth.getTwitterRequest(
       // Http Method
       "GET",
       // Endpoint you are trying to reach
       "statuses/show.json",
       // The options for the request
       options: {
         "id": url.substring(url.lastIndexOf('/')+1, url.indexOf('?')),
       },
     );
   }

   static Future<ApiResponse<String>> resolveUrl(String url, int quality) async{
     ApiResponse<String> apiResponse;
     String rurl = '';
     try{
       rurl = url.substring(url.lastIndexOf('/')+1, url.indexOf('?'));
     }catch(e){
       apiResponse = new ApiResponse(data: null,error: false,errMessage: '');
       return apiResponse;
     }
     
     Future twitterRequest = _twitterOauth.getTwitterRequest(
       // Http Method
       "GET",
       // Endpoint you are trying to reach
       "statuses/show.json",
       // The options for the request
       options: {
         "id": rurl,
         "trim_user": "true",
         "tweet_mode": "extended",
       },
     );
     var res = await twitterRequest;
     String download_url=res.statusCode.toString();
     if(res.statusCode == 200){
       var jsonData = json.decode(res.body);
      // print(jsonData);
       try{
         var jsonvariants = jsonData['extended_entities']['media'][0]['video_info']['variants'];

         download_url = jsonvariants.length==1?jsonvariants[0]['url']:jsonvariants[1]['url'];
         //if(download_url==res.statusCode.toString())download_url = jsonData['extended_entities']['media'][0]['video_info']['variants'][0]['url'];

         List<VVariant> videos = [];
         for(var item in jsonvariants){
           if(item['content_type']!='video/mp4')continue;
           VVariant v = VVariant.videofromJson(item);
           videos.add(v);
         }
         if(videos.length>1) {
           videos.sort((a, b) => a.size.compareTo(b.size));
           Random random = new Random();
           download_url =
               videos[quality == 0 ? random.nextInt(videos.length) : quality ==
                   1 ? 0 : videos.length - 1].url;
         }
       }catch(e){
         print(e.toString());
         try {
           download_url =
           jsonData['extended_entities']['media'][0]['media_url_https'];
         }catch(e){
           download_url = 'null';
         }
       }
       apiResponse = new ApiResponse(data: download_url,error: false,errMessage: '');
       //apiResponse = new ApiResponse(data: jsonData.toString(),error: false,errMessage: '');
     }else{
       apiResponse = new ApiResponse(data: download_url,error: true,errMessage: download_url);
     }


    return apiResponse;
   }


}
