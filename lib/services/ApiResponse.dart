

class ApiResponse<T>{
  T data;
  bool error;
  String errMessage;

  ApiResponse({this.data, this.error, this.errMessage});


}