#include <iostream>
#include <gtkmm.h>

class TTestDialog: public Gtk::Window {
typedef Gtk::Window inherited;
public:
    TTestDialog ();
    void handleDialog (Gtk::Window &parent);
    
private:
    void buttonClicked (bool isOk);

    Gtk::Label label;
    Gtk::Button okButton, cancelButton;
    Gtk::Grid grid;
    Gtk::Box buttonBox;
    
    bool resultCode;
};

TTestDialog::TTestDialog ():
  label ("Hello GTK dialog!", true),
  okButton ("_OK", true),
  cancelButton ("_Cancel", true),
  buttonBox (Gtk::Orientation::HORIZONTAL, 5) {
    set_title ("Test Dialog");
    set_default_size (300, 100);
    set_modal (true);
    set_hide_on_close ();
    
    grid.set_row_spacing (10);
    grid.set_column_spacing (4);
    grid.set_expand (true);
    
    grid.attach (label, 0, 0, 1, 1);
    grid.attach (buttonBox, 0, 1, 1, 1);
    buttonBox.set_halign (Gtk::Align::END);
    buttonBox.append (okButton);
    buttonBox.append (cancelButton);
    
    set_child (grid);    
    okButton.signal_clicked ().connect (sigc::bind (sigc::mem_fun (*this, &TTestDialog::buttonClicked), true));
    cancelButton.signal_clicked ().connect (sigc::bind (sigc::mem_fun (*this, &TTestDialog::buttonClicked), false));
}

void TTestDialog::handleDialog (Gtk::Window &parent) {
    set_transient_for (parent);
    set_visible (true);
}

void TTestDialog::buttonClicked (bool isOk) {
    puts ("Button clicked");
    resultCode = isOk;
    set_visible (false);
}

//

class TMainWindow: public Gtk::ApplicationWindow {
public:
    TMainWindow ();
    virtual ~TMainWindow ();
    
private:
    void onTreeviewRowActivated (const Gtk::TreeModel::Path &, Gtk::TreeViewColumn *);
    
    void buildTreeModel ();
    
    Gtk::Box windowLayout;
    
    Gtk::TreeView treeview;
    
    Glib::RefPtr<Gtk::TreeStore> treeDataModel;
    Gtk::TreeModelColumn<Glib::ustring> nameColumn, windowNameColumn;
    Gtk::TreeModel::ColumnRecord columnRecord;

    Gtk::ScrolledWindow scroll;
    Gtk::Statusbar statusBar;
    
    
};

void TMainWindow::buildTreeModel () {
    columnRecord.add (nameColumn);
    columnRecord.add (windowNameColumn);
    treeDataModel = Gtk::TreeStore::create (columnRecord);
    treeview.set_model (treeDataModel);

    for (int i = 0; i < 200; i++) {
        Gtk::TreeModel::iterator row1 = treeDataModel->append ();
        (*row1) [nameColumn] = std::to_string (i);
        for (int j = 0; j < 200; j++) {
            Gtk::TreeModel::iterator row2 = treeDataModel->append (row1->children ());
            (*row2) [nameColumn] = std::to_string (i) + ":" + std::to_string (j);
            for (int k = 0; k < 200; k++) {
                Gtk::TreeModel::iterator row3 = treeDataModel->append (row2->children ());
                (*row3) [nameColumn] = std::to_string (i) + ":" + std::to_string (j) + ":" + std::to_string (k);
            }
        }
    }
    
    treeview.append_column ("Name", nameColumn);
    treeview.signal_row_activated ().connect (sigc::mem_fun (*this, &TMainWindow::onTreeviewRowActivated));
    treeview.set_activate_on_single_click ();
}

TMainWindow::TMainWindow ():
  windowLayout (Gtk::Orientation::VERTICAL) {
    set_title ("TMainWindow");
    set_default_size (1024, 768);
    
    set_child (windowLayout);
//    windowLayout.append (*Gtk::make_managed<Gtk::PopoverMenuBar>(builder->get_object<Gio::Menu> ("menubar")));

    scroll.set_child (treeview);
    windowLayout.append (scroll);
    windowLayout.append (statusBar);
    
    buildTreeModel ();
    
    treeview.set_vexpand ();

    
    statusBar.push ("Ready");
//    set_can_focus ();
}

void TMainWindow::onTreeviewRowActivated (const Gtk::TreeModel::Path &path, Gtk::TreeViewColumn *) {
    if (Gtk::TreeModel::iterator iter = treeDataModel->get_iter (path)) {
        Gtk::TreeModel::Row row = *iter;
        std::cout << "Clicked: " << row [nameColumn] << std::endl;
    }
}


TMainWindow::~TMainWindow () {
}


class TApplication: public Gtk::Application {
using inherited = Gtk::Application;
public:
    TApplication ();

protected:
    virtual void on_startup () override;
    virtual void on_activate () override;
    
private:
    // event handlers
    void onMenuItem1 ();
    void onMenuItem2 ();
    void onMenuQuit ();
    
    void createMainWindow ();
    
    Glib::RefPtr<Gtk::Builder> builder;
    TMainWindow *mainWindow;
    TTestDialog testDialog;
};

TApplication::TApplication ():
  inherited ("name") {
    Glib::set_application_name ("GTKMM Test Application");
}

void TApplication::on_activate () {
    mainWindow = new TMainWindow;
    add_window (*mainWindow);
    mainWindow->set_show_menubar ();
    mainWindow->set_visible (true);
}


void TApplication::on_startup () {
    inherited::on_startup ();
    
 /*   add_action ("item1", sigc::mem_fun (*this, &TApplication::onMenuItem1));
    add_action ("item2", sigc::mem_fun (*this, &TApplication::onMenuItem2));
    add_action ("quit",  sigc::mem_fun (*this, &TApplication::onMenuQuit));
    
    builder = Gtk::Builder::create ();
    try {
        extern char _binary_menu_xml_start [], _binary_menu_xml_end [];
        builder->add_from_string (Glib::ustring (_binary_menu_xml_start, _binary_menu_xml_end - _binary_menu_xml_start));
    }
    catch (const Glib::Error& e) {
        std::cerr << "Menu failed: " << e.what ();
        throw;
    }
    set_menubar (builder->get_object<Gio::Menu> ("menubar"));
    */
}

void TApplication::onMenuItem1 () {
    testDialog.handleDialog (*mainWindow);
}

void TApplication::onMenuItem2 () {
}

void TApplication::onMenuQuit () {
    mainWindow->set_visible (false);
}


int main (int argc, char **argv) {
    TApplication app;
    app.run (argc, argv);
}