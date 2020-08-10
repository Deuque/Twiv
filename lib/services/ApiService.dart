
import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:twitter_api/twitter_api.dart';

import 'ApiResponse.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
//  https://twitter.com/Kbarbiie2/status/1292529908757999616?s=20

  static String consumerApiKey = "abc";
  static String consumerApiSecret = "abc";
  static String accessToken = "abc";
  static String accessTokenSecret = "abc";

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

   static Future<ApiResponse<String>> resolveUrl(String url) async{
     ApiResponse<String> apiResponse;
     String rurl = '';
     try{
       rurl = url.substring(url.lastIndexOf('/')+1, url.indexOf('?'));
     }catch(e){
       apiResponse = new ApiResponse(data: 'null',error: false,errMessage: '');
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
       },
     );
     var res = await twitterRequest;
     String download_url=res.statusCode.toString();
     if(res.statusCode == 200){
       var jsonData = json.decode(res.body);
       try{
         download_url = jsonData['extended_entities']['media'][0]['video_info']['variants'][1]['url'];
       }catch(e){
         try {
           download_url =
           jsonData['extended_entities']['media'][0]['media_url_https'];
         }catch(e){
           download_url = 'null';
         }
       }
       apiResponse = new ApiResponse(data: download_url,error: false,errMessage: '');
     }else{
       apiResponse = new ApiResponse(data: download_url,error: true,errMessage: 'An error occurred');
     }


    return apiResponse;
   }


}
