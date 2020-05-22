package net.sf.clipsrules.jni.examples.chooseyourphone;

import net.sf.clipsrules.jni.CLIPSException;
import net.sf.clipsrules.jni.Environment;
import net.sf.clipsrules.jni.FactAddressValue;
import net.sf.clipsrules.jni.LexemeValue;
import net.sf.clipsrules.jni.MultifieldValue;
import net.sf.clipsrules.jni.NumberValue;
import net.sf.clipsrules.jni.PrimitiveValue;

import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.*;
import java.awt.*;
import java.awt.event.*;

import java.util.Locale;
import java.util.ResourceBundle;
import java.util.MissingResourceException;

class ChooseYourPhone implements ActionListener {
    JFrame jfrm;
    DefaultTableModel phoneList;

    JComboBox<String> preferredSystem;
    JComboBox<String> preferredScreen;
    JComboBox<String> preferredDualSim;

    JLabel jlab;

    String PreferredSystemNames[] = {"Don't Care", "Android"};
    String PreferredScreenNames[] = {"Don't Care", "Small", "Big"};
    String PreferredDualSimNames[] = {"Don't Care", "Yes"};

    String preferredSystemChoices[] = new String[2];
    String preferredScreenChoices[] = new String[3];
    String preferredDualSimChoices[] = new String[2];

    ResourceBundle phoneResources;

    Environment clips;

    boolean isExecuting = false;
    Thread executionThread;

    class WeightCellRenderer extends JProgressBar implements TableCellRenderer {
        public WeightCellRenderer() {
            super(JProgressBar.HORIZONTAL, 0, 100);
            setStringPainted(false);
        }

        public Component getTableCellRendererComponent(
                JTable table,
                Object value,
                boolean isSelected,
                boolean hasFocus,
                int row,
                int column) {
            setValue(((Number) value).intValue());
            return ChooseYourPhone.WeightCellRenderer.this;
        }
    }


    ChooseYourPhone() {
        try {
            phoneResources = ResourceBundle.getBundle("net.sf.clipsrules.jni.examples.chooseyourphone.resources.phoneResources", Locale.getDefault());
        } catch (MissingResourceException mre) {
            mre.printStackTrace();
            return;
        }

        preferredSystemChoices[0] = phoneResources.getString("Don'tCare");
        preferredSystemChoices[1] = phoneResources.getString("Android");

        preferredDualSimChoices[0] = phoneResources.getString("Don'tCare");
        preferredDualSimChoices[1] = phoneResources.getString("Yes");

        preferredScreenChoices[0] = phoneResources.getString("Don'tCare");
        preferredScreenChoices[1] = phoneResources.getString("Big");
        preferredScreenChoices[2] = phoneResources.getString("Small");


        /*===================================*/
        /* Create a new JFrame container and */
        /* assign a layout manager to it.    */
        /*===================================*/

        jfrm = new JFrame(phoneResources.getString("ChooseYourPhone"));
        jfrm.getContentPane().setLayout(new BoxLayout(jfrm.getContentPane(), BoxLayout.Y_AXIS));

        /*=================================*/
        /* Give the frame an initial size. */
        /*=================================*/

        jfrm.setSize(480, 390);

        /*=============================================================*/
        /* Terminate the program when the user closes the application. */
        /*=============================================================*/

        jfrm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        /*===============================*/
        /* Create the preferences panel. */
        /*===============================*/

        JPanel preferencesPanel = new JPanel();
        GridLayout theLayout = new GridLayout(3, 2);
        preferencesPanel.setLayout(theLayout);
        preferencesPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(),
                phoneResources.getString("PreferencesTitle"),
                TitledBorder.CENTER,
                TitledBorder.ABOVE_TOP));

        preferencesPanel.add(new JLabel(phoneResources.getString("SystemLabel")));
        preferredSystem = new JComboBox<String>(preferredSystemChoices);
        preferencesPanel.add(preferredSystem);
        preferredSystem.addActionListener(this);

        preferencesPanel.add(new JLabel(phoneResources.getString("ScreenLabel")));
        preferredScreen = new JComboBox<String>(preferredScreenChoices);
        preferencesPanel.add(preferredScreen);
        preferredScreen.addActionListener(this);

        preferencesPanel.add(new JLabel(phoneResources.getString("DualSimLabel")));
        preferredDualSim = new JComboBox<String>(preferredDualSimChoices);
        preferencesPanel.add(preferredDualSim);
        preferredDualSim.addActionListener(this);


        /*========================*/
        /* Create the meal panel. */
        /*========================*/

        JPanel mealPanel = new JPanel();
        theLayout = new GridLayout(3, 2);
        mealPanel.setLayout(theLayout);
        mealPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(),
                phoneResources.getString("MealTitle"),
                TitledBorder.CENTER,
                TitledBorder.ABOVE_TOP));


        /*==============================================*/
        /* Create a panel including the preferences and */
        /* meal panels and add it to the content pane.  */
        /*==============================================*/

        JPanel choicesPanel = new JPanel();
        choicesPanel.setLayout(new FlowLayout());
        choicesPanel.add(preferencesPanel);
        choicesPanel.add(mealPanel);

        jfrm.getContentPane().add(choicesPanel);

        /*==================================*/
        /* Create the recommendation panel. */
        /*==================================*/

        phoneList = new DefaultTableModel();

        phoneList.setDataVector(new Object[][]{},
                new Object[]{phoneResources.getString("PhoneTitle"),
                        phoneResources.getString("RecommendationTitle")});

        JTable table =
                new JTable(phoneList) {
                    public boolean isCellEditable(int rowIndex, int vColIndex) {
                        return false;
                    }
                };

        table.setCellSelectionEnabled(false);

        ChooseYourPhone.WeightCellRenderer renderer = this.new WeightCellRenderer();
        renderer.setBackground(table.getBackground());

        table.getColumnModel().getColumn(1).setCellRenderer(renderer);

        JScrollPane pane = new JScrollPane(table);

        table.setPreferredScrollableViewportSize(new Dimension(450, 210));

        /*===================================================*/
        /* Add the recommendation panel to the content pane. */
        /*===================================================*/

        jfrm.getContentPane().add(pane);

        /*===================================================*/
        /* Initially select the first item in each ComboBox. */
        /*===================================================*/

        preferredSystem.setSelectedIndex(0);
        preferredDualSim.setSelectedIndex(0);
        preferredScreen.setSelectedIndex(0);

        /*========================*/
        /* Load the wine program. */
        /*========================*/

        clips = new Environment();

        try {
            clips.loadFromResource("/net/sf/clipsrules/jni/examples/chooseyourphone/resources/phones.clp");
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }

        try {
            runPhone();
        } catch (Exception e) {
            e.printStackTrace();
        }

        /*====================*/
        /* Display the frame. */
        /*====================*/

        jfrm.pack();
        jfrm.setVisible(true);
    }

    /*########################*/
    /* ActionListener Methods */
    /*########################*/

    /*******************/
    /* actionPerformed */

    /*******************/
    public void actionPerformed(
            ActionEvent ae) {
        if (clips == null) return;

        try {
            runPhone();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /***********/
    /* runWine */

    /***********/
    private void runPhone() throws Exception {
        String item;

        if (isExecuting) return;

        clips.reset();

        item = PreferredSystemNames[preferredSystem.getSelectedIndex()];

        if (item.equals("Android")) {
            clips.assertString("(attribute (name preferred-system) (value android))");
        } else {
            clips.assertString("(attribute (name preferred-color) (value unknown))");
        }

        item = PreferredScreenNames[preferredScreen.getSelectedIndex()];

        if(item.equals("Big")){
            clips.assertString("(attribute (name preferred-screen) (value big))");
        } else if(item.equals("Small")){
            clips.assertString("(attribute (name preferred-screen) (value small))");
        }else{
            clips.assertString("(attribute (name preferred-screen) (value unknown))");
        }

        item = PreferredDualSimNames[preferredDualSim.getSelectedIndex()];


        if (item.equals("Yes")) {
            clips.assertString("(attribute (name preferred-dual-sim) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-dual-sim) (value unknown))");
        }

        Runnable runThread =
                new Runnable() {
                    public void run() {
                        try {
                            clips.run();
                        } catch (CLIPSException e) {
                            e.printStackTrace();
                        }

                        SwingUtilities.invokeLater(
                                new Runnable() {
                                    public void run() {
                                        try {
                                            updatePhones();
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                        }
                                    }
                                });
                    }
                };

        isExecuting = true;

        executionThread = new Thread(runThread);

        executionThread.start();
    }

    /***************/
    /* updateWines */

    /***************/
    private void updatePhones() throws Exception {
        String evalStr = "(PHONES::get-phone-list)";

        MultifieldValue mv = (MultifieldValue) clips.eval(evalStr);

        phoneList.setRowCount(0);

        for (PrimitiveValue pv : mv) {
            FactAddressValue fv = (FactAddressValue) pv;

            int certainty = ((NumberValue) fv.getSlotValue("certainty")).intValue();

            String phoneName = ((LexemeValue) fv.getSlotValue("value")).getValue();

            phoneList.addRow(new Object[]{phoneName, new Integer(certainty)});
        }

        jfrm.pack();

        executionThread = null;

        isExecuting = false;
    }

    /********/
    /* main */

    /********/
    public static void main(String args[]) {
        /*===================================================*/
        /* Create the frame on the event dispatching thread. */
        /*===================================================*/

        SwingUtilities.invokeLater(
                new Runnable() {
                    public void run() {
                        new ChooseYourPhone();
                    }
                });
    }

}
