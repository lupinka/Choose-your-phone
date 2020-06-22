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
    JComboBox<String> PreferredScreen;
    JComboBox<String> PreferredPrice;

    JCheckBox preferredDualSim;
    JCheckBox PreferredForGames;
    JCheckBox PreferredForPhotos;
    JCheckBox PreferredBatteryCapacity;
    JCheckBox PreferredDifficultConditions;
    JCheckBox PreferredMultipleApps;
    JCheckBox PreferredBigMemory;
    JCheckBox PreferredForWatching;


    JLabel jlab;

    String[] PreferredSystemNames = {"Don't Care", "Android", "iOS"};
    String[] PreferredScreenNames = {"Don't Care", "Less than 5,5'", "More than 5,5'"};
    String[] PreferredPriceNames = {"Don't Care", "Less than 1000", "1000 to 2000", "More than 2000"};

    String[] preferredSystemChoices = new String[3];
    String[] PreferredScreenChoices = new String[3];
    String[] PreferredPriceChoices = new String[4];

    ResourceBundle phoneResources;

    Environment clips;

    boolean isExecuting = false;
    Thread executionThread;

    static class WeightCellRenderer extends JProgressBar implements TableCellRenderer {
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
        preferredSystemChoices[2] = phoneResources.getString("iOS");

        PreferredScreenChoices[0] = phoneResources.getString("Don'tCare");
        PreferredScreenChoices[1] = phoneResources.getString("Less5");
        PreferredScreenChoices[2] = phoneResources.getString("More5");

        PreferredPriceChoices[0] = phoneResources.getString("Don'tCare");
        PreferredPriceChoices[1] = phoneResources.getString("Less1000");
        PreferredPriceChoices[2] = phoneResources.getString("1000to2000");
        PreferredPriceChoices[3] = phoneResources.getString("More2000");



        /* Create a new JFrame container and */
        /* assign a layout manager to it.    */
        jfrm = new JFrame(phoneResources.getString("ChooseYourPhone"));
        jfrm.getContentPane().setLayout(new BoxLayout(jfrm.getContentPane(), BoxLayout.Y_AXIS));

        /* Give the frame an initial size. */
        jfrm.setSize(480, 390);

        /* Terminate the program when the user closes the application. */
        jfrm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        /* Create the preferences panel. */
        JPanel preferencesPanel = new JPanel();
        GridLayout theLayout = new GridLayout(3, 2);
        preferencesPanel.setLayout(theLayout);
        preferencesPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(),
                phoneResources.getString("PreferencesTitle"),
                TitledBorder.CENTER,
                TitledBorder.ABOVE_TOP));

        preferencesPanel.add(new JLabel(phoneResources.getString("SystemLabel")));
        preferredSystem = new JComboBox<>(preferredSystemChoices);
        preferencesPanel.add(preferredSystem);
        preferredSystem.addActionListener(this);

        preferencesPanel.add(new JLabel(phoneResources.getString("ScreenLabel")));
        PreferredScreen = new JComboBox<>(PreferredScreenChoices);
        preferencesPanel.add(PreferredScreen);
        PreferredScreen.addActionListener(this);

        preferencesPanel.add(new JLabel(phoneResources.getString("PriceLabel")));
        PreferredPrice = new JComboBox<>(PreferredPriceChoices);
        preferencesPanel.add(PreferredPrice);
        PreferredPrice.addActionListener(this);


        /* Create the second panel. */
        JPanel secondPanel = new JPanel();
        theLayout = new GridLayout(8, 2);
        secondPanel.setLayout(theLayout);
        secondPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(),
                phoneResources.getString("SecondTitle"),
                TitledBorder.CENTER,
                TitledBorder.ABOVE_TOP));

//        secondPanel.add(new JLabel(phoneResources.getString("DualSimLabel")));
//        preferredDualSim = new JComboBox<>(preferredDualSimChoices);
//        secondPanel.add(preferredDualSim);
//        preferredDualSim.addActionListener(this);

        secondPanel.add(new JLabel(phoneResources.getString("DualSimLabel")));
        preferredDualSim = new JCheckBox();
        secondPanel.add(preferredDualSim);
        preferredDualSim.addActionListener(this);

        secondPanel.add(new JLabel(phoneResources.getString("BatteryLabel")));
        PreferredBatteryCapacity = new JCheckBox();
        secondPanel.add(PreferredBatteryCapacity);
        PreferredBatteryCapacity.addActionListener(this);

        secondPanel.add(new JLabel(phoneResources.getString("DifficultConditionsLabel")));
        PreferredDifficultConditions = new JCheckBox();
        secondPanel.add(PreferredDifficultConditions);
        PreferredDifficultConditions.addActionListener(this);

        secondPanel.add(new JLabel(phoneResources.getString("MultipleAppsLabel")));
        PreferredMultipleApps = new JCheckBox();
        secondPanel.add(PreferredMultipleApps);
        PreferredMultipleApps.addActionListener(this);

        secondPanel.add(new JLabel(phoneResources.getString("MemoryLabel")));
        PreferredBigMemory = new JCheckBox();
        secondPanel.add(PreferredBigMemory);
        PreferredBigMemory.addActionListener(this);

        secondPanel.add(new JLabel(phoneResources.getString("ForWatchingLabel")));
        PreferredForWatching = new JCheckBox();
        secondPanel.add(PreferredForWatching);
        PreferredForWatching.addActionListener(this);

        secondPanel.add(new JLabel(phoneResources.getString("ForGamesLabel")));
        PreferredForGames = new JCheckBox();
        secondPanel.add(PreferredForGames);
        PreferredForGames.addActionListener(this);

        secondPanel.add(new JLabel(phoneResources.getString("ForPhotosLabel")));
        PreferredForPhotos = new JCheckBox();
        secondPanel.add(PreferredForPhotos);
        PreferredForPhotos.addActionListener(this);


        /* Create a panel including the preferences and */
        /* second panels and add it to the content pane.  */
        JPanel choicesPanel = new JPanel();
        choicesPanel.setLayout(new FlowLayout());
        choicesPanel.add(preferencesPanel);
        choicesPanel.add(secondPanel);

        jfrm.getContentPane().add(choicesPanel);

        /* Create the recommendation panel. */
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

        ChooseYourPhone.WeightCellRenderer renderer = new WeightCellRenderer();
        renderer.setBackground(table.getBackground());

        table.getColumnModel().getColumn(1).setCellRenderer(renderer);

        JScrollPane pane = new JScrollPane(table);

        table.setPreferredScrollableViewportSize(new Dimension(450, 210));

        /* Add the recommendation panel to the content pane. */
        jfrm.getContentPane().add(pane);

        /* Initially select the first item in each ComboBox. */
        preferredSystem.setSelectedIndex(0);
        PreferredScreen.setSelectedIndex(0);
        PreferredPrice.setSelectedIndex(0);

        /* Load the phone program. */
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

        /* Display the frame. */
        jfrm.pack();
        jfrm.setVisible(true);
    }

    /* ActionListener Methods */

    /* actionPerformed */
    public void actionPerformed(
            ActionEvent ae) {
        if (clips == null) return;

        try {
            runPhone();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /* runPhone */
    private void runPhone() throws Exception {
        String item;

        if (isExecuting) return;

        clips.reset();

        item = PreferredSystemNames[preferredSystem.getSelectedIndex()];

        if (item.equals("Android")) {
            clips.assertString("(attribute (name preferred-system) (value android))");
        } else if (item.equals("iOS")) {
            clips.assertString("(attribute (name preferred-system) (value ios))");
        } else {
            clips.assertString("(attribute (name preferred-system) (value unknown))");
        }

        item = PreferredScreenNames[PreferredScreen.getSelectedIndex()];
        if (item.equals("Less than 5,5'")) {
            clips.assertString("(attribute (name preferred-screen-size) (value small))");
        } else if (item.equals("More than 5,5'")) {
            clips.assertString("(attribute (name preferred-screen-size) (value big))");
        } else {
            clips.assertString("(attribute (name preferred-screen-size) (value unknown))");
        }

        item = PreferredPriceNames[PreferredPrice.getSelectedIndex()];
        if (item.equals("Less than 1000")) {
            clips.assertString("(attribute (name preferred-price) (value small))");
        } else if (item.equals("1000 to 2000")) {
            clips.assertString("(attribute (name preferred-price) (value medium))");
        } else if (item.equals("More than 2000")) {
            clips.assertString("(attribute (name preferred-price) (value big))");
        } else {
            clips.assertString("(attribute (name preferred-price) (value unknown))");
        }
        /*checkbox rules*/
        if (preferredDualSim.isSelected()) {
            clips.assertString("(attribute (name preferred-dual-sim) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-dual-sim) (value unknown))");
        }

        if (PreferredForGames.isSelected()) {
            clips.assertString("(attribute (name preferred-games) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-games) (value no))");
        }

        if (PreferredForPhotos.isSelected()) {
            clips.assertString("(attribute (name preferred-photos) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-photos) (value no))");
        }

        if (PreferredBatteryCapacity.isSelected()) {
            clips.assertString("(attribute (name preferred-battery) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-battery) (value no))");
        }

        if (PreferredDifficultConditions.isSelected()) {
            clips.assertString("(attribute (name preferred-ip) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-ip) (value no))");
        }

        if (PreferredMultipleApps.isSelected()) {
            clips.assertString("(attribute (name preferred-multiple-apps) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-multiple-apps) (value no))");
        }

        if (PreferredBigMemory.isSelected()) {
            clips.assertString("(attribute (name preferred-big-memory) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-big-memory) (value no))");
        }

        if (PreferredForWatching.isSelected()) {
            clips.assertString("(attribute (name preferred-movies) (value yes))");
        } else {
            clips.assertString("(attribute (name preferred-movies) (value no))");
        }

        Runnable runThread =
                () -> {
                    try {
                        clips.run();
                    } catch (CLIPSException e) {
                        e.printStackTrace();
                    }

                    SwingUtilities.invokeLater(
                            () -> {
                                try {
                                    updatePhones();
                                } catch (Exception e) {
                                    e.printStackTrace();
                                }
                            });
                };

        isExecuting = true;

        executionThread = new Thread(runThread);

        executionThread.start();
    }

    /* updatePhones */
    private void updatePhones() throws Exception {
        String evalStr = "(PHONES::get-phone-list)";

        MultifieldValue mv = (MultifieldValue) clips.eval(evalStr);

        phoneList.setRowCount(0);

        for (PrimitiveValue pv : mv) {
            FactAddressValue fv = (FactAddressValue) pv;

            int certainty = ((NumberValue) fv.getSlotValue("certainty")).intValue();

            String phoneName = ((LexemeValue) fv.getSlotValue("value")).getValue();
            //String phoneName = String.valueOf(certainty);

            phoneList.addRow(new Object[]{phoneName, certainty});
        }

        jfrm.pack();

        executionThread = null;

        isExecuting = false;
    }

    /* main */
    public static void main(String[] args) {

        /* Create the frame on the event dispatching thread. */
        SwingUtilities.invokeLater(ChooseYourPhone::new);
    }

}
