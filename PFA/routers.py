class MongoRouter:
    mongo_apps = ['patients', 'seances', 'monitoring', 'machines']

    def db_for_read(self, model, **hints):
        if model._meta.app_label in self.mongo_apps:
            return 'mongodb'
        return 'default'

    def db_for_write(self, model, **hints):
        if model._meta.app_label in self.mongo_apps:
            return 'mongodb'
        return 'default'

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        if db == 'mongodb':
            return app_label in self.mongo_apps
        elif db == 'default':
            return app_label not in self.mongo_apps
        return None
