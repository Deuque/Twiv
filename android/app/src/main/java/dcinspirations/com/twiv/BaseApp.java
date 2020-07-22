package dcinspirations.com.twiv;

import android.app.Application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.media.AudioAttributes;
import android.net.Uri;
import android.os.Build;

import io.flutter.plugin.common.MethodChannel;

public class BaseApp extends Application {

    public static final String CHANNEL_1_ID= "channel1";
    public static final String CHANNEL_2_ID= "channel2";
    static MethodChannel.Result myresult;

    @Override
    public void onCreate() {
        super.onCreate();

        createNotificationChannels();
    }

    private void createNotificationChannels() {
        if(Build.VERSION.SDK_INT >=Build.VERSION_CODES.O){

            Uri soundUri = Uri.parse(
                    "android.resource://" +
                            getApplicationContext().getPackageName() +
                            "/" +
                            R.raw.fs);

            AudioAttributes audioAttributes = new AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build();

            NotificationChannel gc = new NotificationChannel(
                    CHANNEL_1_ID,
                    "twiv_channel",
                    NotificationManager.IMPORTANCE_HIGH
            );
            gc.setSound(soundUri, audioAttributes);
            gc.setDescription("twiv channel");

            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(gc);
        }
    }

    public static void createResult(MethodChannel.Result result){
        myresult = result;
    }
}
