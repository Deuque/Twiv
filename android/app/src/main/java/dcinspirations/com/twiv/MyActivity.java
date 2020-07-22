package dcinspirations.com.twiv;

import android.app.Activity;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.GeneratedPluginRegistrant;

import static dcinspirations.com.twiv.BaseApp.CHANNEL_1_ID;
import static dcinspirations.com.twiv.BaseApp.myresult;

public class MyActivity extends FlutterActivity  {
    private static final String CHANNEL = "dcinspirations.com/notifications";
    private Map<String, String> sharedData = new HashMap();
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        GeneratedPluginRegistrant.registerWith(this);

        // Handle intent when app is initially opened
        handleSendIntent(getIntent());
    }
    @Override
    protected void onNewIntent(Intent intent) {
        // Handle intent when app is resumed
        super.onNewIntent(intent);
        handleSendIntent(intent);
    }

    private void handleSendIntent(Intent intent) {
        String action = intent.getAction();
        String type = intent.getType();

        // We only care about sharing intent that contain plain text
        if (Intent.ACTION_SEND.equals(action) && type != null) {
            if ("text/plain".equals(type)) {
                sharedData.put("subject", intent.getStringExtra(Intent.EXTRA_SUBJECT));
                sharedData.put("text", intent.getStringExtra(Intent.EXTRA_TEXT));
            }
        }
    }


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {

                            if (call.method.equals("showNotification")) {
                                String message = call.argument("message");
                                BaseApp.createResult(result);
                                showNotification(message);
//                                result.success("download");
                            }

                            if (call.method.contentEquals("getSharedData")) {
                                result.success(sharedData);
                                sharedData.clear();
                            }
                        }
                );
    }

    private void showNotification(String message) {
        Intent intentAction = new Intent(this,ActionReceiver.class);

//This is optional if you have more than one buttons and want to differentiate between two
        intentAction.putExtra("action","daction");

        PendingIntent pIntentlogin = PendingIntent.getBroadcast(this,1,intentAction, PendingIntent.FLAG_UPDATE_CURRENT);
        NotificationManagerCompat notificationManagerCompat;
        notificationManagerCompat = NotificationManagerCompat.from(this);
        Notification notification = new NotificationCompat.Builder(this,CHANNEL_1_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("Twiv Assitant")
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .addAction(0, "Download", pIntentlogin)
                .setAutoCancel(true)
                .build();

        notification.sound = Uri.parse("android.resource://"
                + getApplicationContext().getPackageName() + "/" + R.raw.fs);
        notificationManagerCompat.notify(0,notification);
    }





}