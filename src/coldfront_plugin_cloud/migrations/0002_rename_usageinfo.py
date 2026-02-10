# Generated migration for renaming UsageInfo to AllocationDailyBillableUsage

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('coldfront_plugin_cloud', '0001_initial'),
    ]

    operations = [
        # Rename the model
        migrations.RenameModel(
            old_name='UsageInfo',
            new_name='AllocationDailyBillableUsage',
        ),
        # Rename the table
        migrations.AlterModelTable(
            name='allocationdailybillableusage',
            table='coldfront_plugin_cloud_allocationdailybillableusage',
        ),
        # Remove the old created_at and updated_at fields
        migrations.RemoveField(
            model_name='allocationdailybillableusage',
            name='created_at',
        ),
        migrations.RemoveField(
            model_name='allocationdailybillableusage',
            name='updated_at',
        ),
        # Add the TimeStampedModel fields (created and modified)
        migrations.AddField(
            model_name='allocationdailybillableusage',
            name='created',
            field=models.DateTimeField(auto_now_add=True, default=None),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='allocationdailybillableusage',
            name='modified',
            field=models.DateTimeField(auto_now=True),
        ),
    ]
