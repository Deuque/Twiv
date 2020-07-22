package dcinspirations.com.twiv;

import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

import static dcinspirations.com.twiv.BaseApp.myresult;

public class ActionReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {

        String action=intent.getStringExtra("action");
        if(action.equals("daction")){

            myresult.success("downloadsssss");
        }
        else if(action.equals("action2")){
            performAction2();

        }
//        //This is used to close the notification tray


        NotificationManager manager = (NotificationManager) context.getSystemService(Context. NOTIFICATION_SERVICE ) ;
        manager.cancel(0) ;
        Intent it = new Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS);
        context.sendBroadcast(it);
    }

    public void performAction1(){

    }

    public void performAction2(){

    }
}