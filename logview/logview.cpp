#include <iostream>
#include <gtkmm.h>
#include <fstream>

class TMainWindow: public Gtk::ApplicationWindow {
public:
    TMainWindow (const std::string &fn);
    virtual ~TMainWindow ();
    
private:
    void onTreeviewRowActivated (const Gtk::TreeModel::Path &, Gtk::TreeViewColumn *);
    
    void buildTreeModel (const std::string &fn);
    int getLevel (const std::string &s);
    
    Gtk::Box windowLayout;
    
    Gtk::TreeView treeview;
    
    Glib::RefPtr<Gtk::TreeStore> treeDataModel;
    Gtk::TreeModelColumn<Glib::ustring> nameColumn, windowNameColumn;
    Gtk::TreeModel::ColumnRecord columnRecord;

    Gtk::ScrolledWindow scroll;
    Gtk::Statusbar statusBar;
};

TMainWindow::TMainWindow (const std::string &fn):
  windowLayout (Gtk::Orientation::VERTICAL) {
    set_title ("TMainWindow");
    set_default_size (1024, 768);
    
    set_child (windowLayout);
//    windowLayout.append (*Gtk::make_managed<Gtk::PopoverMenuBar>(builder->get_object<Gio::Menu> ("menubar")));

    scroll.set_child (treeview);
    windowLayout.append (scroll);
    windowLayout.append (statusBar);
    
    buildTreeModel (fn);
    treeview.set_vexpand ();
    
    statusBar.push ("Ready");
//    set_can_focus ();
}

int TMainWindow::getLevel (const std::string &s) {
    if (s.substr (0, 4) == "Last")
        return 0;
    int count = 0;
    while  (count < s.length () && s [count] == ' ')
        ++count;
    return count / 4;
}

void TMainWindow::buildTreeModel (const std::string &fn) {
    columnRecord.add (nameColumn);
    columnRecord.add (windowNameColumn);
    treeDataModel = Gtk::TreeStore::create (columnRecord);
    treeview.set_model (treeDataModel);
    
    std::ifstream f (fn);
    std::string s;    
    std::array<Gtk::TreeModel::iterator, 100> levels;
    std::int32_t lineCount = 0;

    int lastLevel = 0,
        indent = 0;
    while (getline (f, s)) {
        int level = getLevel (s);
        if (level > lastLevel) 
            ++indent;
        else if (level < lastLevel)
            --indent;
        lastLevel = level;
        if (indent)
            levels [indent] = treeDataModel->append (levels [indent - 1]->children ());
        else
            levels [indent] = treeDataModel->append ();
        (*levels [indent]) [nameColumn] = s + " (" + std::to_string (++lineCount) + ")";
    }
    
    treeview.append_column ("", nameColumn);
    treeview.signal_row_activated ().connect (sigc::mem_fun (*this, &TMainWindow::onTreeviewRowActivated));
    treeview.set_activate_on_single_click ();
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
    TApplication (int argc, char **argv);

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
    int argc;
    char **argv;
//    TTestDialog testDialog;
};

TApplication::TApplication (int argc, char **argv):
  inherited ("name"), argc (argc), argv (argv) {
    Glib::set_application_name ("GTKMM Test Application");
    run (1, argv);
}

void TApplication::on_activate () {
    mainWindow = new TMainWindow (argc == 2 ? argv [1] : "phoenix.log");
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
//    testDialog.handleDialog (*mainWindow);
}

void TApplication::onMenuItem2 () {
}

void TApplication::onMenuQuit () {
    mainWindow->set_visible (false);
}


int main (int argc, char **argv) {
    TApplication app (argc, argv);
}